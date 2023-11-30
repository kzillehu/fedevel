\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   m4_include_lib(['https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program
   
   // Optional:
   // m4_asm(JAL, r7, 00000000000000000000) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   |cpu
      @0
         $reset = *reset;
         
         // ZHK code here
         //pipelined RISC-V core logic 
         $start = (>>1$reset && !$reset) ? 1'b1 : 1'b0;
         
         $valid = $reset ? 1'b0 :
                  $start ? 1'b1 :
                  >>3$valid;
         
         $pc[31:0] = >>1$reset ? 32'b0 :
                     >>1$taken_br ? >>1$br_tgt_pc :
                     >>1$pc + 32'd4;
         
         $imem_rd_en = !$reset;
      ?$imem_rd_en
         @0
            $imem_rd_addr[M4_IMEM_INDEX_CNT-1:0] = $pc[M4_IMEM_INDEX_CNT+1:2];
      
      @1
         $instr[31:0] = $imem_rd_data;
         
         $is_i_instr = $instr[6:2] ==? 5'b0000x || 
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==? 5'b11001;
                 
         $is_u_instr = $instr[6:2] ==? 5'b0x101;
         
         $is_s_instr = $instr[6:2] ==? 5'b0100x;
         
         $is_r_instr = $instr[6:2] ==? 5'b01011 || 
                       $instr[6:2] ==? 5'b01100 ||
                       $instr[6:2] ==? 5'b01110 ||
                       $instr[6:2] ==? 5'b10100;
                       
         $is_b_instr = $instr[6:2] ==? 5'b11000;
         
         $is_j_instr = $instr[6:2] ==? 5'b11011;
         
         $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         
         $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
         
         $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
         
         $funct7_valid = $is_r_instr; //can simply use is_r_instr as the when condition
         
         $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr; //can simply use $rs1_valid since funct3 is only valid when rs1 is valid
         
         $opcode_valid = 1;	//opcode is always valid;
         
         $imm_valid = !$is_r_instr;
         
         ?$imm_valid
            $imm[31:0] = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20]} :
                         $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7] } :
                         $is_b_instr ? { {20{$instr[31]}}, $instr[7],  $instr[30:25], $instr[11:8], 1'b0} :
                         $is_u_instr ? { $instr[31], $instr[30:20],  $instr[19:12], 12'd0 } :
                         $is_j_instr ? { {12{$instr[31]}}, $instr[19:12],  $instr[20], $instr[30:21], 1'b0 } :
                         '0;
         
         ?$funct7_valid
            $funct7[6:0] = $instr[31:25]; 
         
         ?$funct3_valid
            $funct3[2:0] = $instr[14:12];
            
         ?$rs1_valid
            $rs1[4:0] = $instr[19:15];
            $rf_rd_index1[4:0] = $rs1;
         
         ?$rs2_valid
            $rs2[4:0] = $instr[24:20];
            $rf_rd_index2[4:0] = $rs2;
         
         ?$rd_valid
            $rd[4:0] = $instr[11:7];
            $rf_wr_index[4:0] = $rd;
         
         ?$opcode_valid
            $opcode[6:0] = $instr[6:0];
         
         //RF enable assignments
         $rf_rd_en1 = $rs1_valid;
         
         $rf_rd_en2 = $rs2_valid;
         
         $rf_wr_en = $rd_valid && !($rd ==? 5'b0);
         
         $src1_value[31:0] = $rf_rd_data1;
         $src2_value[31:0] = $rf_rd_data2;
        
         //collect bit vector called dec_bits
         $dec_bits[10:0] = { $funct7[5], $funct3, $opcode};
         
         $is_beq = $dec_bits ==? 11'bx_000_1100011;
         $is_bne = $dec_bits ==? 11'bx_001_1100011;
         $is_blt = $dec_bits ==? 11'bx_100_1100011;
         $is_bge = $dec_bits ==? 11'bx_101_1100011;
         $is_bltu = $dec_bits ==? 11'bx_110_1100011;
         $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
         
         $is_addi = $dec_bits ==? 11'bx_000_0010011;
         
         $is_add = $dec_bits ==? 11'b0_000_0110011;
         
         //ALU operations
         $result[31:0] = $is_addi ? $src1_value + $imm :
                         $is_add ? $src1_value + $src2_value :
                         32'bx;
                         
         $rf_wr_data[31:0] = $result;
         
         $taken_br = $is_beq ? $src1_value == $src2_value :
                     $is_bne ? $src1_value != $src2_value :
                     $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                     $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                     $is_bltu ? $src1_value < $src2_value :
                     $is_bgeu ? $src1_value >= $src2_value :
                     1'b0;
         
         $br_tgt_pc[31:0] = $pc + $imm;
         
         `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $taken_br)

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   //*passed = *cyc_cnt > 40;
   *passed = |cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9);	//just go forward a couple of cycles
   *failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@1, @1)  // Args: (read stage, write stage) - if equal, no register bypass is required
      //m4+dmem(@4)    // Args: (read/write stage)
      //m4+myth_fpga(@0)  // Uncomment to run on fpga

   m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.
\SV
   endmodule