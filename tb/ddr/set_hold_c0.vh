// $Id: set_hold.vh,v 1.1.2.5 2010/06/29 12:03:41 pboya Exp $
//
//------------------------------------------------------------
//
//                    Q I M O N D A
//
// This document is the property of Qimonda.
// For terms and conditions see License.txt
//
//------------------------------------------------------------
//
//    Setup&Hold Checks Config file for Verilog model for
//         QI DDR2 SDRAM Behavioral Verilog Model
//
//  $Revision: 1.1.2.5 $  
//
//  $Date: 2010/06/29 12:03:41 $
//
//  Autor: Radovan Vuletic, Qimonda AG, QAG PD PDE MEM MEM
//         mailto:dram-models@qimonda.com
//
//------------------------------------------------------------

   always @(posedge CK)  #0.0 check_PosEdge_CK_Timing;
   always @(posedge bCK) #0.0 check_PosEdge_bCK_Timing;
   always @(negedge CK)  #0.0 check_NegEdge_CK_Timing;
   always @(negedge bCK) #0.0 check_NegEdge_bCK_Timing;
   
   always @(bCS)      check_bCS__Timing;
   always @(bRAS)     check_bRAS_Timing;
   always @(bCAS)     check_bCAS_Timing;
   always @(bWE)      check_bWE__Timing;
   
   always @(BA[0])    check_BA___Timing(0);
   always @(BA[1])    check_BA___Timing(1);
   always @(BA[2])    check_BA___Timing(2);
   
   always @(Addr[0])  check_Addr_Timing(0);
   always @(Addr[1])  check_Addr_Timing(1);
   always @(Addr[2])  check_Addr_Timing(2);
   always @(Addr[3])  check_Addr_Timing(3);
   always @(Addr[4])  check_Addr_Timing(4);
   always @(Addr[5])  check_Addr_Timing(5);
   always @(Addr[6])  check_Addr_Timing(6);
   always @(Addr[7])  check_Addr_Timing(7);
   always @(Addr[8])  check_Addr_Timing(8);
   always @(Addr[9])  check_Addr_Timing(9);
   always @(Addr[10]) check_Addr_Timing(10);
   always @(Addr[11]) check_Addr_Timing(11);
   always @(Addr[12]) check_Addr_Timing(12);
   
`ifdef X16
   always @(DQ[0])  check_DQ_Timing(0);
   always @(DQ[1])  check_DQ_Timing(1);
   always @(DQ[2])  check_DQ_Timing(2);
   always @(DQ[3])  check_DQ_Timing(3);
   always @(DQ[4])  check_DQ_Timing(4);
   always @(DQ[5])  check_DQ_Timing(5);
   always @(DQ[6])  check_DQ_Timing(6);
   always @(DQ[7])  check_DQ_Timing(7);
   always @(DQ[8])  check_DQ_Timing(8);
   always @(DQ[9])  check_DQ_Timing(9);
   always @(DQ[10]) check_DQ_Timing(10);
   always @(DQ[11]) check_DQ_Timing(11);
   always @(DQ[12]) check_DQ_Timing(12);
   always @(DQ[13]) check_DQ_Timing(13);
   always @(DQ[14]) check_DQ_Timing(14);
   always @(DQ[15]) check_DQ_Timing(15);
   
   always @(UDM)  check_UDM_Timing;
   always @(LDM)  check_LDM_Timing;

   always @(UDQS) check_UDQS_Timing;
   always @(LDQS) check_LDQS_Timing;

   always @(posedge UDQS) check_PosEdge_UDQS_Timing;
   always @(posedge LDQS) check_PosEdge_LDQS_Timing;

   always @(negedge UDQS) check_NegEdge_UDQS_Timing;
   always @(negedge LDQS) check_NegEdge_LDQS_Timing;
`else // !`ifdef X16
 `ifdef X4
   always @(Addr[13]) check_Addr_Timing(13);
   
   always @(DQ[0])  check_DQ_Timing(0);
   always @(DQ[1])  check_DQ_Timing(1);
   always @(DQ[2])  check_DQ_Timing(2);
   always @(DQ[3])  check_DQ_Timing(3);
   
   always @(DM)  check_DM_Timing;

   always @(DQS) check_DQS_Timing;

   always @(posedge DQS) check_PosEdge_DQS_Timing;

   always @(negedge DQS) check_NegEdge_DQS_Timing;
 `else // !`ifdef X4
   always @(Addr[13]) check_Addr_Timing(13);
   
   always @(DQ[0])  check_DQ_Timing(0);
   always @(DQ[1])  check_DQ_Timing(1);
   always @(DQ[2])  check_DQ_Timing(2);
   always @(DQ[3])  check_DQ_Timing(3);
   always @(DQ[4])  check_DQ_Timing(4);
   always @(DQ[5])  check_DQ_Timing(5);
   always @(DQ[6])  check_DQ_Timing(6);
   always @(DQ[7])  check_DQ_Timing(7);
   
   always @(DM)  check_DM_Timing;
   
   always @(DQS) check_DQS_Timing;

   always @(posedge DQS) check_PosEdge_DQS_Timing;

   always @(negedge DQS) check_NegEdge_DQS_Timing;
 `endif // !`ifdef X4
`endif // !`ifdef X16

   task check_PosEdge_CK_Timing;
      begin
	 last_pos_CK = $realtime;
	 if (init === 1'b0) begin
	    if ($realtime - last_neg_CK + `INF < tCL*curr_tCK) begin
               $display ("QI ERR %m, %t :   tCL violation on CK by %0t", $realtime, last_neg_CK + tCL*curr_tCK - $realtime);
	    end
            if ($realtime - last_CKE + `INF < tIS) begin
               $display ("QI ERR %m, %t :   tIS violation on CKE by %0t", $realtime, last_CKE + tIS - $realtime);
	    end
	    if ($realtime - last_bCS + `INF < tIS) begin
               $display ("QI ERR %m, %t :   tIS violation on bCS by %0t", $realtime, last_bCS + tIS - $realtime);
	    end
	    if ($realtime - last_bRAS + `INF < tIS) begin
               $display ("QI ERR %m, %t :   tIS violation on bRAS by %0t", $realtime, last_bRAS + tIS - $realtime);
	    end
	    if ($realtime - last_bCAS + `INF < tIS) begin
               $display ("QI ERR %m, %t :   tIS violation on bCAS by %0t", $realtime, last_bCAS + tIS - $realtime);
	    end
	    if ($realtime - last_bWE + `INF < tIS) begin
               $display ("QI ERR %m, %t :   tIS violation on bWE by %0t %0t %0t", $realtime, last_bWE + tIS - $realtime,
			 last_bWE, tIS);
	    end
            for (i=0; i<addr_bits; i=i+1) begin
               if ($realtime - $bitstoreal(last_Addr[i]) + `INF < tIS) begin
		  $display ("QI ERR %m, %t :   tIS violation on Addr[%0d] by %0t", 
			    $realtime, i, $bitstoreal(last_Addr[i]) + tIS - $realtime);
	       end
	    end
	    for (i=0; i<bank_bits; i=i+1) begin
               if ($realtime - $bitstoreal(last_BA[i]) + `INF < tIS) begin
		  $display ("QI ERR %m, %t :   tIS violation on BA[%0d] by %0t", 
			    $realtime, i, $bitstoreal(last_BA[i]) + tIS - $realtime);
	       end
	    end
`ifdef X16
	    if (valid_WR_Data && ($realtime - $bitstoreal(last_neg_UDQS) + `INF < tDSS*curr_tCK))
              $display ("QI ERR %m, %t : tDSS violation on UDQS", $realtime);
            if (valid_WR_Data && !check_negEdge_WR_UDQS)
              $display ("QI ERR %m, %t : Missing UDQS falling edge during the preceding clock period", $realtime);
	    if (valid_WR_Data && ($realtime - $bitstoreal(last_neg_LDQS) + `INF < tDSS*curr_tCK))
              $display ("QI ERR %m, %t : tDSS violation on LDQS", $realtime);
            if (valid_WR_Data && !check_negEdge_WR_LDQS)
              $display ("QI ERR %m, %t : Missing LDQS falling edge during the preceding clock period", $realtime);
	    check_negEdge_WR_UDQS <= 1'b0;
	    check_negEdge_WR_LDQS <= 1'b0;		
`else
            if (valid_WR_Data && ($realtime - $bitstoreal(last_neg_DQS) + `INF < tDSS*curr_tCK))
              $display ("QI ERR %m, %t : tDSS violation on DQS", $realtime);
            if (valid_WR_Data && !check_negEdge_WR_DQS)
              $display ("QI ERR %m, %t : Missing DQS falling edge during the preceding clock period", $realtime);
	    if (WR_pipe[4:3] !== 2'b10 && WR_pipe[3:2] !== 2'b10)
	      check_negEdge_WR_DQS <= 1'b0;
`endif
	 end // if (init === 1'b0)
      end
   endtask // check_PosEdge_CK_Timing
   
   task check_PosEdge_bCK_Timing;
      begin 
	 last_pos_bCK = $realtime;
	 if (init === 1'b0) begin
	    if ($realtime - last_neg_bCK + `INF < tCL*curr_tCK) begin
               $display ("QI ERR %m, %t :   tCL violation on bCK by %0t", $realtime, last_neg_bCK + tCL*curr_tCK - $realtime);
	    end 
	 end // if (init === 1'b0)
      end
   endtask // check_PosEdge_bCK_Timing
   
   task check_NegEdge_CK_Timing;
      begin
	 last_neg_CK = $realtime;
	 if (init === 1'b0) begin
	    if ($realtime - last_pos_CK + `INF < tCH*curr_tCK) begin
               $display ("QI ERR %m, %t :   tCH violation on CK by %0t", $realtime, last_pos_CK + tCH*curr_tCK - $realtime);
	    end
`ifdef X16
            if (valid_WR_Data) begin
	       last_tDQSS = $realtobits(abs_value(last_pos_CK - $bitstoreal(last_pos_UDQSS)));
	       if (($bitstoreal(last_tDQSS) + `INF < curr_tCK/2.0) && ($bitstoreal(last_tDQSS) > tDQSS*curr_tCK + `INF)) begin
                  $display ("QI ERR %m, %t : tDQSS violation on UDQS", $realtime);
	       end
            end
            if (valid_WR_Data && !check_posEdge_WR_UDQS) begin
	       $display ("QI ERR %m, %t : Missing UDQS rising edge during the preceding clock period", $realtime);
	    end
	    if (valid_WR_Data) begin
	       last_tDQSS = $realtobits(abs_value(last_pos_CK - $bitstoreal(last_pos_LDQSS)));
	       if (($bitstoreal(last_tDQSS) + `INF < curr_tCK/2.0) && ($bitstoreal(last_tDQSS) > tDQSS*curr_tCK + `INF)) begin
                  $display ("QI ERR %m, %t : tDQSS violation on LDQS", $realtime);
	       end
            end
            if (valid_WR_Data && !check_posEdge_WR_LDQS) begin
	       $display ("QI ERR %m, %t : Missing LDQS rising edge during the preceding clock period", $realtime);
	    end
	    check_posEdge_WR_UDQS   <= 1'b0;
	    check_posEdge_WR_LDQS   <= 1'b0;
`else // !`ifdef X16
            if (valid_WR_Data) begin
	       last_tDQSS = $realtobits(abs_value(last_pos_CK - $bitstoreal(last_pos_DQSS)));
	       if (($bitstoreal(last_tDQSS) + `INF < curr_tCK/2.0) && ($bitstoreal(last_tDQSS) > tDQSS*curr_tCK + `INF)) begin
                  $display ("QI ERR %m, %t : tDQSS violation on DQS", $realtime);
	       end
            end
            if (valid_WR_Data && !check_posEdge_WR_DQS) begin
	       $display ("QI ERR %m, %t : Missing DQS rising edge during the preceding clock period", $realtime);
	    end
	    check_posEdge_WR_DQS   <= 1'b0;
`endif // !`ifdef X16
	end // if (init === 1'b0)
      end
   endtask // check_NegEdge_CK_Timing

   task check_NegEdge_bCK_Timing;
      begin
	 last_neg_bCK = $realtime;
	 if (init === 1'b0) begin
	    if ($realtime - last_pos_bCK + `INF < tCH*curr_tCK) begin
               $display ("QI ERR %m, %t :   tCH violation on bCK by %0t", $realtime, last_pos_bCK + tCH*curr_tCK - $realtime);
	    end
	 end // if (init === 1'b0)
      end
   endtask // check_NegEdge_bCK_Timing
      
   task check_DQ_Timing;
      input i;
      integer i;      
      begin
	 if (init === 1'b0) begin
            if (valid_WR_Data) begin
`ifdef X16
	       if(i>7) begin
		  if ($realtime - $bitstoreal(last_UDQS) + `INF < tDH) begin
		     $display ("QI ERR %m, %t :   tDH violation on DQ[%0d] by %0t", 
			       $realtime, i, $bitstoreal(last_UDQS) + tDH - $realtime);
		  end
	       end
	       else begin
		  if ($realtime - $bitstoreal(last_LDQS) + `INF < tDH) begin
		     $display ("QI ERR %m, %t :   tDH violation on DQ[%0d] by %0t", 
			       $realtime, i, $bitstoreal(last_LDQS) + tDH - $realtime);
		  end
	       end // else: !if(i>7)
`else
               if ($realtime - $bitstoreal(last_DQS[i/8]) + `INF < tDH) begin 
		  $display ("QI ERR %m, %t :   tDH violation on DQ[%0d] by %0t", 
			    $realtime, i, $bitstoreal(last_DQS[i/8]) + tDH - $realtime);
	       end
`endif
               if (check_DQ_tDIPW[i]) begin
		  if ($realtime - $bitstoreal(last_DQ[i]) + `INF < tDIPW*curr_tCK) begin
                     $display ("QI ERR %m, %t : tDIPW violation on DQ[%0d] by %0t", 
			       $realtime, i, $bitstoreal(last_DQ[i]) + tDIPW*curr_tCK - $realtime);
		  end
               end
            end
            check_DQ_tDIPW[i] <= 1'b0;
            last_DQ[i]         = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_DQ_Timing

   task check_DQS_Timing;
      integer j;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_DM) + `INF < tDS) begin 
		  $display ("QI ERR %m, %t : tDS violation on DM by %0t", 
			    $realtime, $bitstoreal(last_DM) + tDS - $realtime);
	       end
	       check_DM_tDIPW <= 1'b1;
`ifdef X4
	       for (j=0; j<4; j=j+1) begin
`else
		  for (j=0; j<8; j=j+1) begin
`endif
		     if ($realtime - $bitstoreal(last_DQ[j]) + `INF < tDS) begin
			$display ("QI ERR %m, %t : tDS violation on DQ[%0d] by %0t", 
				  $realtime, j, $bitstoreal(last_DQ[j]) + tDS - $realtime);
		     end
		     check_DQ_tDIPW[j] <= 1'b1;
		  end
	       end
	       last_DQS = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_DQS_Timing

   task check_UDQS_Timing;
      integer j;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_UDM) + `INF < tDS) begin
		  $display ("QI ERR %m, %t : tDS violation on UDM by %0t", 
			    $realtime, $bitstoreal(last_UDM) + tDS - $realtime);
	       end
	       check_UDM_tDIPW <= 1'b1;
	       for (j=8; j<16; j=j+1) begin
		  if ($realtime - $bitstoreal(last_DQ[j]) + `INF < tDS) begin
		     $display ("QI ERR %m, %t : tDS violation on DQ[%0d] by %0t", 
			       $realtime, j, $bitstoreal(last_DQ[j]) + tDS - $realtime);
		  end
		  check_DQ_tDIPW[j] <= 1'b1;
	       end
	    end
	    last_UDQS = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_UDQS_Timing

   task check_LDQS_Timing;
      integer j;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_LDM) + `INF < tDS) begin
		  $display ("QI ERR %m, %t : tDS violation on LDM by %0t", 
			    $realtime, $bitstoreal(last_LDM) + tDS - $realtime);
	       end
	       check_LDM_tDIPW <= 1'b1;
	       for (j=0; j<8; j=j+1) begin
		  if ($realtime - $bitstoreal(last_DQ[j]) + `INF < tDS) begin
		     $display ("QI ERR %m, %t : tDS violation on DQ[%0d] by %0t", 
			       $realtime, j, $bitstoreal(last_DQ[j]) + tDS - $realtime);
		  end
		  check_DQ_tDIPW[j] <= 1'b1;
	       end
	    end
	    last_LDQS = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_LDQS_Timing
   
   task check_PosEdge_DQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (check_DQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_neg_DQS) + `INF < tWPRE*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPRE violation on DQS by %0t", 
			    $realtime, $bitstoreal(last_neg_DQS) + tWPRE*curr_tCK - $realtime);
	       end
	    end
	    if (check_DQS_WR_Postamble) begin
	       if ($realtime - $bitstoreal(last_neg_DQS) + `INF < tWPST*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPST violation on DQS by %0t", 
			    $realtime, $bitstoreal(last_neg_DQS) + tWPST*curr_tCK - $realtime);
	       end
	    end 
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_neg_DQS) + `INF < tDQSL*curr_tCK) begin
		  $display ("QI ERR %m, %t : tDQSL violation on DQS by %0t", 
			    $realtime, $bitstoreal(last_neg_DQS) + tDQSL*curr_tCK - $realtime);
	       end
	    end
	    check_DQS_WR_Preamble  <= 1'b0;
	    check_DQS_WR_Postamble <= 1'b0;
`ifdef X16
`else
	    if(DQS !== 1'bz) begin
	       check_posEdge_WR_DQS   <= 1'b1;
	       last_pos_DQSS          <= $realtobits($realtime);
	       last_pos_DQS            = $realtobits($realtime);
	    end
`endif
	 end // if (init === 1'b0)
      end
   endtask // check_PosEdge_DQS_Timing

   task check_PosEdge_UDQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (check_UDQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_neg_UDQS) + `INF < tWPRE*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPRE violation on UDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_UDQS) + tWPRE*curr_tCK - $realtime);
	       end
	    end
	    if (check_UDQS_WR_Postamble) begin
	       if ($realtime - $bitstoreal(last_neg_UDQS) + `INF < tWPST*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPST violation on UDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_UDQS) + tWPST*curr_tCK - $realtime);
	       end
	    end 
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_neg_UDQS) + `INF < tDQSL*curr_tCK) begin
		  $display ("QI ERR %m, %t : tDQSL violation on UDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_UDQS) + tDQSL*curr_tCK - $realtime);
	       end
	    end
	    check_UDQS_WR_Preamble  <= 1'b0;
	    check_UDQS_WR_Postamble <= 1'b0;
`ifdef X16
	    if(UDQS !== 1'bz) begin
	       check_posEdge_WR_UDQS   <= 1'b1;
	       last_pos_UDQSS          <= $realtobits($realtime);
	       last_pos_UDQS            = $realtobits($realtime);
	    end
`endif
	 end // if (init === 1'b0)
      end
   endtask // check_PosEdge_UDQS_Timing

   task check_PosEdge_LDQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (check_LDQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_neg_LDQS) + `INF < tWPRE*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPRE violation on LDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_LDQS) + tWPRE*curr_tCK - $realtime);
	       end
	    end
	    if (check_LDQS_WR_Postamble) begin
	       if ($realtime - $bitstoreal(last_neg_LDQS) + `INF < tWPST*curr_tCK) begin
		  $display ("QI ERR %m, %t : tWPST violation on LDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_LDQS) + tWPST*curr_tCK - $realtime);
	       end
	    end 
	    if (valid_WR_Data) begin
	       if ($realtime - $bitstoreal(last_neg_LDQS) + `INF < tDQSL*curr_tCK) begin
		  $display ("QI ERR %m, %t : tDQSL violation on LDQS by %0t", 
			    $realtime, $bitstoreal(last_neg_LDQS) + tDQSL*curr_tCK - $realtime);
	       end
	    end
	    check_LDQS_WR_Preamble  <= 1'b0;
	    check_LDQS_WR_Postamble <= 1'b0;
`ifdef X16
	    if(LDQS !== 1'bz) begin
	       check_posEdge_WR_LDQS   <= 1'b1;
	       last_pos_LDQSS          <= $realtobits($realtime);
	       last_pos_LDQS            = $realtobits($realtime);
	    end
`endif  
	 end // if (init === 1'b0)
      end
   endtask // check_PosEdge_LDQS_Timing
   
   task check_NegEdge_DQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data && !check_DQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_pos_DQS) + `INF < tDQSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDQSH violation on DQS by %0t", 
			   $realtime, $bitstoreal(last_pos_DQS) + tDQSH*curr_tCK - $realtime);
	       if ($realtime - last_pos_CK + `INF < tDSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDSH violation on DQS", $realtime); 
	    end
	    check_negEdge_WR_DQS <= 1'b1;
	    last_neg_DQS          = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_NegEdge_DQS_Timing

   task check_NegEdge_UDQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data && !check_UDQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_pos_UDQS) + `INF < tDQSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDQSH violation on UDQS by %0t", 
			   $realtime, $bitstoreal(last_pos_UDQS) + tDQSH*curr_tCK - $realtime);
	       if ($realtime - last_pos_CK + `INF < tDSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDSH violation on UDQS", $realtime); 
	    end
	    check_negEdge_WR_UDQS <= 1'b1;
	    last_neg_UDQS          = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_NegEdge_UDQS_Timing

   task check_NegEdge_LDQS_Timing;
      begin
	 if (init === 1'b0) begin
	    if (valid_WR_Data && !check_LDQS_WR_Preamble) begin
	       if ($realtime - $bitstoreal(last_pos_LDQS) + `INF < tDQSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDQSH violation on LDQS by %0t", 
			   $realtime, $bitstoreal(last_pos_LDQS) + tDQSH*curr_tCK - $realtime);
	       if ($realtime - last_pos_CK + `INF < tDSH*curr_tCK)
		 $display ("QI ERR %m, %t : tDSH violation on LDQS", $realtime); 
	    end
	    check_negEdge_WR_LDQS <= 1'b1;
	    last_neg_LDQS          = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_NegEdge_LDQS_Timing
   
   task check_DM_Timing;
      begin
	 if (init === 1'b0) begin 
            if (valid_WR_Data) begin
               if ($realtime - $bitstoreal(last_DQS) + `INF < tDH) 
		 $display ("QI ERR %m, %t :   tDH violation on DM by %0t", 
			   $realtime, $bitstoreal(last_DQS) + tDH - $realtime);
               if (check_DM_tDIPW) begin
		  if ($realtime - $bitstoreal(last_DM) + `INF < tDIPW*curr_tCK)
                    $display ("QI ERR %m, %t : tDIPW violation on DM by %0t", 
			      $realtime, $bitstoreal(last_DM) + tDIPW*curr_tCK - $realtime);
               end
            end
            check_DM_tDIPW <= 1'b0;
            last_DM         = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_DM_Timing

   task check_UDM_Timing;
      begin
	 if (init === 1'b0) begin 
            if (valid_WR_Data) begin
               if ($realtime - $bitstoreal(last_UDQS) + `INF < tDH) 
		 $display ("QI ERR %m, %t :   tDH violation on UDM by %0t", 
			   $realtime, $bitstoreal(last_UDQS) + tDH - $realtime);
               if (check_UDM_tDIPW) begin
		  if ($realtime - $bitstoreal(last_UDM) + `INF < tDIPW*curr_tCK)
                    $display ("QI ERR %m, %t : tDIPW violation on UDM by %0t", 
			      $realtime, $bitstoreal(last_UDM) + tDIPW*curr_tCK - $realtime);
               end
            end
            check_UDM_tDIPW <= 1'b0;
            last_UDM         = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_UDM_Timing

   task check_LDM_Timing;
      begin
	 if (init === 1'b0) begin 
            if (valid_WR_Data) begin
               if ($realtime - $bitstoreal(last_LDQS) + `INF < tDH) 
		 $display ("QI ERR %m, %t :   tDH violation on LDM by %0t", 
			   $realtime, $bitstoreal(last_LDQS) + tDH - $realtime);
               if (check_LDM_tDIPW) begin
		  if ($realtime - $bitstoreal(last_LDM) + `INF < tDIPW*curr_tCK)
                    $display ("QI ERR %m, %t : tDIPW violation on LDM by %0t", 
			      $realtime, $bitstoreal(last_LDM) + tDIPW*curr_tCK - $realtime);
               end
            end
            check_LDM_tDIPW <= 1'b0;
            last_LDM         = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_LDM_Timing

   task check_bCS__Timing;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on bCS by %0t", $realtime, last_pos_CK + tIH - $realtime);
               if ($realtime - last_bCS + `INF < tIPW*curr_tCK)
		 $display ("QI ERR %m, %t : tIPW violation on bCS by %0t", $realtime, last_bCS + tIPW*curr_tCK - $realtime);
            end
            last_bCS = $realtime;
	 end
      end
   endtask // check_bCS__Timing

   task check_bRAS_Timing;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on bRAS by %0t", $realtime, last_pos_CK + tIH - $realtime);
               if ($realtime - last_bRAS + `INF < tIPW*curr_tCK)
		 $display ("QI ERR %m, %t : tIPW violation on bRAS by %0t", $realtime, last_bRAS + tIPW*curr_tCK - $realtime);
            end
            last_bRAS = $realtime;
	 end
      end
   endtask // check_bRAS_Timing

   task check_bCAS_Timing;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on bCAS by %0t", $realtime, last_pos_CK + tIH - $realtime);
               if ($realtime - last_bCAS + `INF < tIPW*curr_tCK)
		 $display ("QI ERR %m, %t : tIPW violation on bCAS by %0t", $realtime, last_bCAS + tIPW*curr_tCK - $realtime);
            end
            last_bCAS = $realtime;
	 end
      end
   endtask // check_bCAS_Timing

   task check_bWE__Timing;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on bWE by %0t", $realtime, last_pos_CK + tIH - $realtime);
               if ($realtime - last_bWE + `INF < tIPW*curr_tCK)
              $display ("QI ERR %m, %t : tIPW violation on bWE by %0t", $realtime, last_bWE + tIPW*curr_tCK - $realtime);
            end
            last_bWE = $realtime;
	 end
      end
   endtask // check__bWE_Timing

   task check_Addr_Timing;
      input i;
      integer i;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on Addr[%0d] by %0t", 
			   $realtime, i, last_pos_CK + tIH - $realtime);
               if ($realtime - $bitstoreal(last_Addr[i]) + `INF < tIPW*curr_tCK)
		 $display ("QI ERR %m, %t : tIPW violation on Addr[%0d] by %0t", 
			   $realtime, i, $bitstoreal(last_Addr[i]) + tIPW*curr_tCK - $realtime);
            end
            last_Addr[i] = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_Addr_Timing
   
   task check_BA___Timing;
      input i;
      integer i;
      begin
	 if (init === 1'b0) begin
            if (CKE) begin
               if ($realtime - last_pos_CK + `INF < tIH) 
		 $display ("QI ERR %m, %t :  tIH violation on BA[%0d] by %0t", 
			   $realtime, i, last_pos_CK + tIH - $realtime);
               if ($realtime - $bitstoreal(last_BA[i]) + `INF < tIPW*curr_tCK)
		 $display ("QI ERR %m, %t : tIPW violation on BA[%0d] by %0t", 
			   $realtime, i, $bitstoreal(last_BA[i]) + tIPW*curr_tCK - $realtime);
            end
            last_BA[i] = $realtobits($realtime);
	 end // if (init === 1'b0)
      end
   endtask // check_BA___Timing
   

