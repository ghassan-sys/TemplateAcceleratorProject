package templateMMIOAcc 
// scala collections


import chisel3._
import chisel3.util._
import chisel3.experimental.{IntParam, BaseModule}
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.subsystem.BaseSubsystem
import freechips.rocketchip.config.{Parameters, Field, Config}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper.{HasRegMap, RegField}
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util.UIntIsOneOf


case object MMIOKey extends Field[Option[TemplateMMIOParams]](None)


// DOC include start: MMIO params
case class TemplateMMIOParams(
  address: BigInt = 0x50000,
  DATA_WIDTH: Int = 8,
  ADDR_WIDTH: Int = 16,
  CFG_REG_WIDTH: Int = 16,
  NUM_OF_CFG_REGS: Int = 1024,
  MEM_DATA_WIDTH: Int = 1100,
  BUFF_SIZE: Int = 256,
  LATENCY: Int = 2000,
  MEMORY_BANDWIDTH: Int = 300)
// DOC include end: MMIO params

class MMIO_IO() extends Bundle {
  val tap = TemplateMMIOParams()
  val clock = Input(Clock())
  val reset = Input(Bool())
  val input_ready = Output(Bool())
  val input_valid = Input(Bool())
  val output_ready = Input(Bool())
  val output_valid = Output(Bool())
  val busy = Output(Bool())
  val data_out = Output(UInt(32.W))
  val funct_cfg_reg = Input(UInt(tap.CFG_REG_WIDTH.W))
}


trait MMIOTopIO extends Bundle {
  val mmio_busy = Output(Bool())
}

trait HasMMIO_IO extends BaseModule {
//  val w: Int
  val io = IO(new MMIO_IO())
}



// DOC include start: MMIO blackbox
class MMIOAccBlackBox(tap: TemplateMMIOParams) (implicit p: Parameters) extends BlackBox(Map("address" -> IntParam(tap.address), "DATA_WIDTH" -> IntParam(tap.DATA_WIDTH), "ADDR_WIDTH" -> IntParam(tap.ADDR_WIDTH), "CFG_REG_WIDTH" -> IntParam(tap.CFG_REG_WIDTH), "NUM_OF_CFG_REGS" -> IntParam(tap.NUM_OF_CFG_REGS), "MEM_DATA_WIDTH" -> IntParam(tap.MEM_DATA_WIDTH), "BUFF_SIZE" -> IntParam(tap.BUFF_SIZE), "LATENCY" -> IntParam(tap.LATENCY))) with HasBlackBoxResource
  with HasMMIO_IO
{
  addResource("/vsrc/MMIOAccBlackBox.v")
}
// DOC include end: MMIO blackbox


// DOC include start: GCD instance regmap

trait MMIOModule extends HasRegMap {
  val io: MMIOTopIO

  implicit val p: Parameters
  def params: TemplateMMIOParams
  val clock: Clock
  val reset: Reset
  val impl = Module(new MMIOAccBlackBox(params))
  val status = Wire(UInt(2.W))
  val data_out = Wire(new DecoupledIO(UInt(32.W)))
  val funct = Wire(new DecoupledIO(UInt(params.CFG_REG_WIDTH.W)))

  impl.io.clock        := clock
  impl.io.reset        := reset.asBool
  impl.io.funct_cfg_reg := funct.bits
  impl.io.input_valid := funct.valid
  funct.ready := impl.io.input_ready

  data_out.bits := impl.io.data_out
  data_out.valid := impl.io.output_valid
  impl.io.output_ready := data_out.ready

  status := Cat(impl.io.input_ready, impl.io.output_valid)
  io.mmio_busy := impl.io.busy

 regmap(
    0x00 -> Seq(
      RegField.r(2, status)), // read-only
    0x04 -> Seq (
      RegField.w(params.CFG_REG_WIDTH, funct)),
    0x08 -> Seq(
      RegField.r(32, data_out))) // read-only, gcd.ready is set on read
}
// DOC include end: MMIO instance regmap


// DOC include start: MMIO router
class MMIOTL(params: TemplateMMIOParams, beatBytes: Int)(implicit p: Parameters)
  extends TLRegisterRouter(
    params.address, "mmio", Seq("ucbbar,mmio"),
    beatBytes = beatBytes)(
      new TLRegBundle(params, _) with MMIOTopIO)(
      new TLRegModule(params, _, _) with MMIOModule)


trait CanHavePeripheryMMIO {this: BaseSubsystem =>
  private val portName = "mmio"

  val mmio = p(MMIOKey) match {
    case Some(params) => {
      val mmio = LazyModule(new MMIOTL(params, pbus.beatBytes)(p))
      pbus.toVariableWidthSlave(Some(portName)){mmio.node}
      Some(mmio)
    }
    case None => None
  }
}

trait CanHavePeripheryMMIOModuleImp extends LazyModuleImp{
  val outer : CanHavePeripheryMMIO
  val mmio_busy = outer.mmio match {
    case Some(mmio) => {
      val busy = IO(Output(Bool()))
      busy := mmio.module.io.mmio_busy
      Some(busy)
    }
    case None => None
  }
}



// DOC include start: MMIO config fragment
class WithMMIO() extends Config((site, here, up) => {case MMIOKey => Some(TemplateMMIOParams())})
// DOC include end: MMIO config fragment
