\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // Welcome!  New to Makerchip? Try the "Learn" menu.
   // =================================================
   
   //use(m5-1.0)   /// uncomment to use M5 macro library.
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   
   |calc
      @0 
         $reset = *reset;
      @1
         //sequential calculator
         
         $val2[31:0] = $rand2[3:0];
         $val1[31:0] = >>2$out;
         
         $sum[31:0] = $val1 + $val2;
         $diff[31:0] = $val1 - $val2;
         $prod[31:0] = $val1 * $val2;
         $quot[31:0] = $val1 / $val2;
         
         $valid = $reset ? 0 : >>1$valid + 1;
         
         $valid_or_rest = $valid || $reset;
      ?$valid_or_reset   
         @2
            $out[31:0] = $op[1:0] == 2'd3 ? $quot :
                         $op[1:0] == 2'd2 ? $prod :
                         $op[1:0] == 2'd1 ? $diff :
                         //default
                         $sum;
        
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule