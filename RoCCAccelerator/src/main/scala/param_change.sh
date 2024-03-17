#!/bin/bash
file_path_scala=templateAcc.scala
file_path_test=../../../software/tests/src/gemmini-rocc-tests/bareMetalC/templateAccTest.c
#need to open the test change the values 
file_contents_scala=$(<"$file_path_scala")
file_contents_test=$(<"$file_path_test")
DATA_WIDTH_VALUES=(8)
ADDR_WIDTH_VALUES=(8 16 32 64)
CFG_REG_WIDTH_VALUES=(8 16 32 64)
NUM_OF_CFG_REGS_VALUES=(2 16 256 1024)
MEM_DATA_WIDTH_VALUES=(1100)
BUFF_SIZE_VALUES=(256)
LATENCY_VALUES=(200 2000)
MEMORY_BANDWIDTH_VALUES=(300)
collect_progress_scala=()

collect_progress_test=()

touch collected_runs.csv
touch regression_RoCC
echo "DATA_WIDTH, ADDR_WIDTH, CFG_REG_WIDTH, NUM_OF_CFG_REGS, MEM_DATA_WIDTH, BUFF_SIZE, LATENCY, MEMORY_BANDWIDTH, RESULT OF TEST" > collected_runs.csv

for DATA_WIDTH in "${DATA_WIDTH_VALUES[@]}"; do
  for ADDR_WIDTH in "${ADDR_WIDTH_VALUES[@]}"; do
    for CFG_REG_WIDTH in "${CFG_REG_WIDTH_VALUES[@]}"; do
      for NUM_OF_CFG_REGS in "${NUM_OF_CFG_REGS_VALUES[@]}"; do
        for MEM_DATA_WIDTH in "${MEM_DATA_WIDTH_VALUES[@]}"; do
          for BUFF_SIZE in "${BUFF_SIZE_VALUES[@]}"; do
            for LATENCY in "${LATENCY_VALUES[@]}"; do
              for MEMORY_BANDWIDTH in "${MEMORY_BANDWIDTH_VALUES[@]}"; do
                modified_contents_scala=$(echo "$file_contents_scala" | sed "s/DATA_WIDTH: Int = [0-9]*/DATA_WIDTH: Int = $DATA_WIDTH/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/ADDR_WIDTH: Int = [0-9]*/ADDR_WIDTH: Int = $ADDR_WIDTH/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/CFG_REG_WIDTH: Int = [0-9]*/CFG_REG_WIDTH: Int = $CFG_REG_WIDTH/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/NUM_OF_CFG_REGS: Int = [0-9]*/NUM_OF_CFG_REGS: Int = $NUM_OF_CFG_REGS/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/MEM_DATA_WIDTH: Int = [0-9]*/MEM_DATA_WIDTH: Int = $MEM_DATA_WIDTH/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/BUFF_SIZE: Int = [0-9]*/BUFF_SIZE: Int = $BUFF_SIZE/")
                modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/LATENCY: Int = [0-9]*/LATENCY: Int = $LATENCY/")
		modified_contents_scala=$(echo "$modified_contents_scala" | sed "s/MEMORY_BANDWIDTH: Int = [0-9]*/MEMORY_BANDWIDTH: Int = $MEMORY_BANDWIDTH/")
	        echo "$modified_contents_scala" >"$file_path_scala"


	        modified_contents_test=$(echo "$file_contents_test" | sed "s/#define DATA_WIDTH [0-9]\+/#define DATA_WIDTH $DATA_WIDTH/")
                modified_contents_test=$(echo "$modified_contents_test" | sed "s/#define ADDR_WIDTH [0-9]\+/#define ADDR_WIDTH $ADDR_WIDTH/")
                modified_contents_test=$(echo "$modified_contents_test" | sed "s/#define CFG_REG_WIDTH [0-9]\+/#define CFG_REG_WIDTH $CFG_REG_WIDTH/")
                modified_contents_test=$(echo "$modified_contents_test" | sed "s/#define NUM_OF_CFG_REGS [0-9]\+/#define NUM_OF_CFG_REGS $NUM_OF_CFG_REGS/")
                echo "$modified_contents_test" >"$file_path_test"
		cd ../../../software/tests/src/gemmini-rocc-tests/
		./build.sh
		cd ../../../../src/main/scala/
                  
            
		cd ../../../../../sims/verilator/
		make clean 
		
		make run-binary-debug BINARY=../../generators/template_accelerator_proj/software/tests/src/gemmini-rocc-tests/build/bareMetalC/templateAccTest-baremetal CONFIG=templateAccConfig timeout_cycles=100000000 > RoCC_flog
		collect_progress_scala=($(grep -oE "RoCC Accelerator SUCCESS! execution took [0-9]+ cycles" RoCC_flog | grep -oE '[0-9]+'))
		data="$DATA_WIDTH, $ADDR_WIDTH, $CFG_REG_WIDTH, $NUM_OF_CFG_REGS, $MEM_DATA_WIDTH, $BUFF_SIZE, $LATENCY, $MEMORY_BANDWIDTH, $collect_progress_scala"
		echo "data" >> ../../generators/template_accelerator_proj/src/main/scala/regression_RoCC
		#cat RoCC_flog >> ../../generators/template_accelerator_proj/src/main/scala/regression_RoCC
		echo "-------------------------------------------------------------------------------------------" >> ../../generators/template_accelerator_proj/src/main/scala/regression_RoCC

		cd output/chipyard.TestHarness.templateAccConfig/
		#rm -rf templateAccTest-baremetal.vcd templateAccTest-baremetal.out templateAccTest-baremetal.log
 		cd ../../
		rm RoCC_flog

		cd ../../generators/template_accelerator_proj/src/main/scala
		echo "$data" >>collected_runs.csv
               
              
              done
            done
          done
        done
      done
    done
  done
done

echo " finished the tests, this is the output: ${collect_progress[@]}"

