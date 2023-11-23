\m4_TLV_version 1d: tl-x.org
\SV
   m4_makerchip_module
\TLV
   
   |comp
      
      //a non trivial pipeline for exception handling 
      @1
         $err1 = $bad_input || $illegal_op;
      @3
         $err2 = $err1 || $overflow;
      @6
         $err3 = $err2 || $div_by_zero;
         
         
         
      
         
   // Stop simulation.
   *passed = *cyc_cnt > 40;
\SV
endmodule
