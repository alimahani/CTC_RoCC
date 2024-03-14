`timescale 1ns/1ns
// ----------------------------------------------------------------------
// Copyright (c)
//
//
//
//
// ----------------------------------------------------------------------
//----------------------------------------------------------------------------
// Filename:			top_module.v
// Version:		     3.00
// Verilog Standard:	Verilog
// Description:		
//
//
//
//
// Author:				ALI MAHANI
// History:				09-2023
//-----------------------------------------------------------------------------

module top_module #(
	parameter C_PCI_DATA_WIDTH = 8'd128
)
(
	input                        CLK,
	input                        RST,
	input                        RX_REQ, 
	output                       RX_ACK, 
	input [31:0]                 RX_LENGTH, 
	input [C_PCI_DATA_WIDTH-1:0] RX_DATA, 
	input                        RX_DATA_VALID, 
	output reg                   RX_DATA_READY,
	
	output                       TX_REQ, 
	input                        TX_ACK, 
	output reg [31:0]            TX_LENGTH, 
	output [C_PCI_DATA_WIDTH-1:0]TX_DATA, 
	output                       TX_DATA_VALID, 
	input                        TX_DATA_READY
);






wire CLKd;

reg [C_PCI_DATA_WIDTH-1:0] offp_reg [1:0]                = {{128'd0}, {128'd0}};
reg [C_PCI_DATA_WIDTH-1:0] prev_score1 [1:0];
reg [15:0]                 stay_prob                  = 1'b0;

wire [127:0]               TX_REQ_1;//            = 128'd0;

reg  [9:0]                 prev_Count              = 10'd0;
reg  [15:0]                update_Count            = 16'd0;
reg  [10:0]                uCount                  = 10'd0;
reg  [32:0]                probe_Counter            = 32'd0; 
reg                        trace_en                 = 1'b0;
reg                        start_tmp                = 1'b0; 
reg                        mem_switch               = 1'b0;
reg                 	  Tx_Count                 = 64'd0;
wire                       valid_trace;  
wire  [15:0]               trace_out;
wire                       imvalid_trace;
wire                       tmp_upd_done;                                   


//****************************************
//  RxState (initial scores)
//*****************************************

wire [31:0]                dina1;
wire [31:0]                dinb1;
wire [31:0]                dina2;
wire [31:0]                dinb2;
wire [31:0]                dina3;
wire [31:0]                dinb3;
wire [31:0]                dina4;
wire [31:0]                dinb4;

//****************************************
//  log_post address
//*****************************************

reg  [7:0]                 addra1p      = 1'b0;
reg  [7:0]                 addra2p      = 1'b0;
reg  [7:0]                 addra3p      = 1'b0;
reg  [7:0]                 addra4p      = 1'b0;
reg  [7:0]                 addrb1p      = 1'b0;
reg  [7:0]                 addrb2p      = 1'b0;
reg  [7:0]                 addrb3p      = 1'b0;
reg  [7:0]                 addrb4p      = 1'b0;


//****************************************
//  
//*****************************************
wire [31:0]                dina1_l;
wire [31:0]                dinb1_l;
wire [31:0]                dina2_l;
wire [31:0]                dinb2_l;
wire [31:0]                dina3_l;
wire [31:0]                dinb3_l;
wire [31:0]                dina4_l;
wire [31:0]                dinb4_l;

reg  [7:0]                 addra1_l    = 1'b0;
reg  [7:0]                 addrb1_l    = 1'b0;
reg  [7:0]                 addra2_l    = 1'b0;
reg  [7:0]                 addrb2_l    = 1'b0;
reg  [7:0]                 addra3_l    = 1'b0;
reg  [7:0]                 addrb3_l    = 1'b0;
reg  [7:0]                 addra4_l    = 1'b0;
reg  [7:0]                 addrb4_l    = 1'b0;
reg  [7:0]                 logaddr     = 1'b0;
                  
 integer i = 0;
 integer j = 0;       

//****************************************
//  state machines
//*****************************************

reg  [31:0] rLen                   = 31'd0;
reg  [31:0] tLen                   = 31'd0;
reg  [31:0] rCount                 = 31'd0;
reg  [31:0] tCount                 = 31'd0;
reg  [9:0]  cCount                 = 10'd0;
reg  [63:0] Rx_Count               = 63'd0;
reg  [2:0]  temp_Count             = 3'd0; 
reg  [3:0] Rxstate                 = 4'd0;
reg  [3:0] Rxstate2                = 4'd0; 
reg  [3:0] Exestate1               = 4'd0;
reg  [3:0] Txstate                 = 4'd0;
reg startRxstate2                  = 1'b0;

reg [31:0] total_count             = 32'd0; 



assign RX_ACK                     = (Rxstate == 4'd1);

assign TX_REQ                    = (Txstate != 3'd0);
assign TX_DATA_VALID         = Txstate == 4'd3;


clk_wiz_0  clk_inst0(
.clk_in1(CLK),
.reset(RST),
.clk_out1(CLKd)
);


always @(posedge CLKd or posedge RST) begin

	if (RST) begin
	
		rLen                               <= 32'd0;
		tLen                               <= 32'd0; 
		rCount                             <= 32'd0;
		tCount                             <= 32'd0;
		Rx_Count                           <= 64'd0;
		Tx_Count                           <= 64'd0;
		temp_Count                         <= 3'd0;
		prev_Count                         <= 10'd0;
		cCount                             <= 10'd0;
		uCount                             <= 10'd0;
		update_Count                       <= 16'd0;
		Rxstate                            <= 4'd0;
		Rxstate2                           <= 4'd0;
		Exestate1                          <= 4'd0; 
		Txstate                            <= 3'd0;
        logaddr                            <= 8'd0; 
        addra1_l                           <= 8'd0;
        addrb1_l                           <= 8'd0;
        addra2_l                           <= 8'd0;
        addrb2_l                           <= 8'd0; 
        addra3_l                           <= 8'd0;
        addrb3_l                           <= 8'd0;
        addra4_l                           <= 8'd0;
        addrb4_l                           <= 8'd0; 
        probe_Counter                      <= 32'd0;
        stay_prob                          <= 16'd0;
        startRxstate2                      <= 1'b0;  
        start_tmp                          <= 1'b0; 
        mem_switch                         <= 1'b0;
        
        total_count                        <= 32'd0; 

	end
	
	else begin

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                   // rcv state machine  "riffa interface" //
////////////////////////////////////////////////////////////////////////////////////////////////////////////

		case (Rxstate)

    4'd0: begin 

               Rxstate                                  <= Rxstate + RX_REQ;
                                     
          end
  
    4'd1: begin              

              Rxstate                                   <= Rxstate + RX_DATA_VALID;
              RX_DATA_READY                             <= RX_DATA_VALID;
              rLen                                      <= RX_LENGTH / 10'd516;                      
              prev_Count                                <= 10'd0;
              temp_Count                                <= 1'b0; 
              uCount                                    <= 1'b0;

         end
  
    4'd2: begin         //rcv the stay probability (1025 elements) of raw data
  
              Rxstate                                     <= (uCount >= 1) ? Rxstate + 1'b1 : Rxstate;
              Rx_Count                                    <= (uCount < 1) ? RX_DATA[63:0] : Rx_Count;
              Tx_Count                                    <= (uCount < 1) ? RX_DATA[63:0] : Tx_Count;                        
              update_Count                                <= 1'b0;
              uCount                                      <= (uCount >= 1) ? 1'b0 : uCount + 1'b1;
                                              
          end 
          
    4'd3: begin         //rcv the stay probability (1025 elements) of raw data
        
               prev_score1[temp_Count]                    <= RX_DATA;  
               temp_Count                                 <= (temp_Count >= 1) ? 1'b0 : temp_Count + 1'b1; 
               rCount                                     <= rCount + 1'b1;                                               

               addra1p                                     <= update_Count;    // generate the address to store the scores inside the memory
               addra2p                                     <= update_Count;
               addra3p                                     <= update_Count;
               addra4p                                     <= update_Count;
               
               addrb1p                                     <= update_Count + 1'b1;
               addrb2p                                     <= update_Count + 1'b1;
               addrb3p                                     <= update_Count + 1'b1;
               addrb4p                                     <= update_Count + 1'b1;              

               RX_DATA_READY                           <= (temp_Count >= 1) ? 1'b0 : RX_DATA_VALID;
               Rxstate                                    <= (temp_Count >= 1) ? Rxstate + 1'b1 : Rxstate;                       
        
          end                       
                        
    4'd4: begin     //rcv first column


               rCount                                       <= (rCount >= 8'd127) ? 32'd0 : rCount;
               Rxstate                                      <= (rCount >= 8'd127) ? 4'd5 : 2'd3;              //write the data into the memory and check the condition to exit 
               RX_DATA_READY                                <= (rCount >= 8'd127) ? 1'b0 : RX_DATA_VALID; 
               startRxstate2                                <= (rCount >= 8'd127) ? 1'b1 : 1'b0; 
               update_Count                                 <= (rCount >= 8'd127) ? 1'b0 : update_Count + 2'd2;
               probe_Counter                                <= (rCount >= 8'd127) ? probe_Counter + 1'b1 : probe_Counter; 
               rLen                                         <= (rCount >= 8'd127) ? rLen - 1'b1 : rLen; 
               Rx_Count                                     <= (rCount >= 8'd127) ? Rx_Count - 1'b1 : Rx_Count;
                            
           end     

           
      4'd5: begin           //should be changed
        
                Rxstate                                         <= (RX_REQ ? 4'd5 : 4'd0);
                                        
                end 
           
                      
endcase
      
      
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                         // rcv state machine  "After first column" //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
 if (startRxstate2 == 1'b1) begin
 
      
              case (Rxstate2)
              
                  4'd0: begin 
      
                             Rxstate2                                 <= (Rx_Count > 1'b0) ? Rxstate2 + RX_DATA_VALID : 1'b0;
                             RX_DATA_READY                            <= RX_DATA_VALID;
                                                     
                        end

                  4'd1: begin 
      
                             Rxstate2                                   <= Rxstate2 + 1'b1;
                             stay_prob                                  <= RX_DATA[15:0]; 
                                                     
                        end

                        
                  4'd2: begin
                        
                            offp_reg[rCount]                             <= RX_DATA;
                            rCount                                       <= (rCount < 3'd1) ? (rCount + 1'b1) : 1'b0;
                            cCount                                       <= (rCount >= 3'd1) ? cCount + 2'd2 : cCount; 
                            Rxstate2                                     <= (rCount >= 3'd1) ? (Rxstate2 + 1'b1) : Rxstate2;
                            RX_DATA_READY                                <= (rCount >= 3'd1) ? 1'b0 : RX_DATA_VALID;
      
      //address generation for logpost 
                             
                             addra1_l                                    <= logaddr;
                             addra2_l                                    <= logaddr;
                             addra3_l                                    <= logaddr;
                             addra4_l                                    <= logaddr;
      
                             addrb1_l                                    <= logaddr + 1'b1;                      
                             addrb2_l                                    <= logaddr + 1'b1;                      
                             addrb3_l                                    <= logaddr + 1'b1;                      
                             addrb4_l                                    <= logaddr + 1'b1;                                                 
                        
                         end     
                        
                  4'd3: begin
      
                             RX_DATA_READY                                <= (cCount >= 8'd128) ? 1'b0 : RX_DATA_VALID; 
                             logaddr                                      <= (cCount < 8'd128) ? logaddr + 2'd2 : logaddr;
                             Rxstate2                                     <= (cCount >= 8'd128) ? 4'd4 : 4'd2; 
                                            
                         end     
                                
                    4'd4: begin 
                   
                              Rxstate2                                        <= 1'b0;
                              startRxstate2                                   <= 1'b0;
                              logaddr                                         <= 1'b0; 
                              rCount                                          <= 1'b0;
                              cCount                                          <= 1'b0;
                              probe_Counter                                   <= probe_Counter + 1'b1; 
                              rLen                                            <= rLen - 1'b1; 
                              Rx_Count                                        <= Rx_Count - 1'b1;                                                                                                                                                      
                                                      
                         end 
                                      
            endcase
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    Exe state machine
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
           
       case (Exestate1)
 
             4'd0: begin
             
                        Exestate1                                                <= Exestate1 + tmp_upd_done;
                        start_tmp                                                <= (Rxstate == 3'd4 & rCount >= 8'd127) | tmp_upd_done;  
                        mem_switch                                               <= (tmp_upd_done == 1'b1) ? !mem_switch : mem_switch;                                               
              
                   end

             4'd1: begin
                  
                        startRxstate2                                            <= (Rx_Count > 1'b0) ? 1'b1 : 1'b0; 
                        start_tmp                                                <= 1'b0;
                        Exestate1                                                <= 1'b0;                        
                                                

                
                   end
      endcase


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                        Tx state machine 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


           case (Txstate)
          
              4'd0: begin                  // Wait for finish the traceback update 
       
                     Txstate                         <= valid_trace;  //transmission in parallel with skip score to prevscore replacement
                     total_count                     <= (start_tmp == 1'b1) ? 1'b0 : total_count + 1'b1;  //just to find the ctc_cycle count

             end

              4'd1: begin                  // Wait for finish the traceback update 
          
                        Txstate                         <= Txstate + 1'b1;  //transmission in parallel with skip score to prevscore replacement
                        TX_LENGTH                     <= ((Tx_Count - 6'd31) * 3'd4);   //32'd772 + 10'd512; 
              
                end
   
              4'd2: begin                  // Wait for the TX_ACK
          
                         tCount                         <= 16'd0;
                         Txstate                        <= Txstate + (TX_ACK);
   
                end
          
              4'd3: begin // 
                
                          Txstate                       <= Txstate + TX_DATA_READY;  
                                                                        
                      end

              4'd4: begin      // Finish the TX transaction
    
                          Txstate                                 <= ((Rx_Count > 1'b0) & (valid_trace == 1'b1)) ? 2'd3 : ((Rx_Count > 1'b0) ? 3'd4 : Txstate + 1'b1); 
                          tCount                                  <= 1'b0;
                     end
               
               4'd5: begin      // Finish the TX transaction
          
                           Txstate                                 <= ((Rx_Count == 1'b0) & ((valid_trace == 1'b1) | (imvalid_trace == 1'b1))) ? 2'd3 : 4'd5; 
     
                     end
      
   
          endcase
    end

 end

 
 
 
                
 //***********************************************************************************
 //                 Initial values prev_scores
 //***********************************************************************************               
                  

                assign dina1                      = {{prev_score1[0][31:16]}, {prev_score1[0][15:0]}};
                assign dinb1                      = {{prev_score1[0][63:48]}, {prev_score1[0][47:32]}};
                assign dina2                      = {{prev_score1[0][95:80]}, {prev_score1[0][79:64]}};
                assign dinb2                      = {{prev_score1[0][127:112]}, {prev_score1[0][111:96]}};
                assign dina3                      = {{prev_score1[1][31:16]}, {prev_score1[1][15:0]}};
                assign dinb3                      = {{prev_score1[1][63:48]}, {prev_score1[1][47:32]}};
                assign dina4                      = {{prev_score1[1][95:80]}, {prev_score1[1][79:64]}};
                assign dinb4                      = {{prev_score1[1][127:112]}, {prev_score1[1][111:96]}};



//*****************************************************************************************
//                       TX_DATA value
//*****************************************************************************************

                assign TX_DATA                    = (Txstate == 3'd3) ?  TX_REQ_1 : 128'd0;
                assign TX_REQ_1 [127:0]           = {{112'd0},{trace_out}};

                
//******************************************************************************************
//                           logposts
//*******************************************************************************************                
                
  
                 assign dina1_l                      = {{offp_reg[0][31:16]}, {offp_reg[0][15:0]}}    ;
                 assign dinb1_l                      = {{offp_reg[0][63:48]}, {offp_reg[0][47:32]}}   ;
                 assign dina2_l                      = {{offp_reg[0][95:80]}, {offp_reg[0][79:64]}}   ;
                 assign dinb2_l                      = {{offp_reg[0][127:112]}, {offp_reg[0][111:96]}};
                 assign dina3_l                      = {{offp_reg[1][31:16]}, {offp_reg[1][15:0]}}    ;
                 assign dinb3_l                      = {{offp_reg[1][63:48]}, {offp_reg[1][47:32]}}   ;
                 assign dina4_l                      = {{offp_reg[1][95:80]}, {offp_reg[1][79:64]}}   ;
                 assign dinb4_l                      = {{offp_reg[1][127:112]}, {offp_reg[1][111:96]}};
                 




//*********************************************************************************************************************************
//                                                  ctc/traceback
//*********************************************************************************************************************************

      

tmp_upd  parallel_tmp_upd(
 .clock(CLKd),
 .reset(RST),
 .io_prev_score_0(dina1[15:0]),
 .io_prev_score_1(dina1[31:16]),
 .io_prev_score_2(dinb1[15:0]),
 .io_prev_score_3(dinb1[31:16]),
 .io_prev_score_4(dina2[15:0]), 
 .io_prev_score_5(dina2[31:16]),
 .io_prev_score_6(dinb2[15:0]), 
 .io_prev_score_7(dinb2[31:16]),
 .io_prev_score_8(dina3[15:0]), 
 .io_prev_score_9(dina3[31:16]),
 .io_prev_score_10(dinb3[15:0]), 
 .io_prev_score_11(dinb3[31:16]),
 .io_prev_score_12(dina4[15:0]), 
 .io_prev_score_13(dina4[31:16]),
 .io_prev_score_14(dinb4[15:0]), 
 .io_prev_score_15(dinb4[31:16]),
 .io_start_addr(update_Count),
 .io_wr_score(Rxstate == 3'd4),
 .io_ping_pong(mem_switch),
 .io_start_tmp(start_tmp),
 .io_skip_pen(16'd0),
 .io_logpost_0(dina1_l[15:0]),     
 .io_logpost_1(dina1_l[31:16]),     
 .io_logpost_2(dinb1_l[15:0]),     
 .io_logpost_3(dinb1_l[31:16]),     
 .io_logpost_4(dina2_l[15:0]),     
 .io_logpost_5(dina2_l[31:16]),     
 .io_logpost_6(dinb2_l[15:0]),     
 .io_logpost_7(dinb2_l[31:16]),     
 .io_logpost_8(dina3_l[15:0]),     
 .io_logpost_9(dina3_l[31:16]),     
 .io_logpost_10(dinb3_l[15:0]),    
 .io_logpost_11(dinb3_l[31:16]),    
 .io_logpost_12(dina4_l[15:0]),    
 .io_logpost_13(dina4_l[31:16]),    
 .io_logpost_14(dinb4_l[15:0]),    
 .io_logpost_15(dinb4_l[31:16]),
 .io_offsetp_nkmer(stay_prob), 
 .io_wr_logpost(Rxstate2 == 3'd3),
 .io_logpost_addr(logaddr),    
 .io_wrlogpost_done(Rxstate2 == 3'd4),
 .io_traceback_0(),   
 .io_traceback_1(),   
 .io_traceback_2(),   
 .io_traceback_3(),   
 .io_traceback_4(),   
 .io_traceback_5(),   
 .io_traceback_6(),   
 .io_traceback_7(),   
 .io_traceback_8(),   
 .io_traceback_9(),   
 .io_traceback_10(),  
 .io_traceback_11(),  
 .io_traceback_12(),  
 .io_traceback_13(),  
 .io_traceback_14(),  
 .io_traceback_15(),
 .io_tmp_upd_done(tmp_upd_done),
 .io_valid_traceback(valid_trace),
 .io_im_valid(imvalid_trace),
 .io_ev_count(probe_Counter - 2'd2),
 .io_trace_out(trace_out)    
);



endmodule
