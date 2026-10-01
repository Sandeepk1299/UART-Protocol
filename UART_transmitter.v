/* TRANSMITTER */

module UART_TRANSMITTER #(
                            parameter DataWidth = 8
                        )(
                            input t_clk,
                            input reset,
                            input send,
                            input load,
                            input [DataWidth-1:0] data_in,
                            output Tx,
                            output busy
                        );
wire baud_tick;
wire [DataWidth+2 : 0] packet;
baud_gen B_T(
                .t_clk(t_clk),
                .reset(reset),
                .baud_tick(baud_tick)
            );

frame_data #(.DataWidth(DataWidth))
                            P_T(
                                .data_in(data_in),
                                .packet(packet)
                                );

transmitter #(.DataWidth(DataWidth))
            T(
            .t_clk(t_clk),
            .baud_tick(baud_tick),
            .reset(reset),
            .send(send),
            .load(load),
            .packet(packet),
            .Tx(Tx),
            .busy(busy)
            );

endmodule

// baudrate of transmitter = 3906250bps i.e 260ns
// transmitter clk period  = 16ns 
// hence for 260ns we use clock divider of 16 (since 16*16 = 256 approx(260) )

module baud_gen (
    input t_clk,
    input reset,
    output baud_tick
);

reg [4:0] count = 1;
reg baud_tick_reg;
always @(posedge t_clk,posedge reset) 
begin
    if(reset)
    begin 
        count <= 1;
        baud_tick_reg <= 1'b0;
    end
    else if(count==16)     // count = 16 since // time period of clock = 16ns  // one baud tick of transmitter occurs for every 256ns i.e 260ns
    begin
        count <= 1;
        baud_tick_reg <= 1'b1;
    end
    else 
    begin
        count <= count + 1;
        baud_tick_reg <= 1'b0;
    end        
end

assign baud_tick = baud_tick_reg;

endmodule

module frame_data#(
                    parameter DataWidth = 8
                )(
            
                        input  [DataWidth-1:0] data_in,
                        output [DataWidth+2:0] packet
                );

wire p ;
assign p = ~(^data_in);
// packet making 
assign packet = {1'b1,p,data_in[7:0],1'b0};

endmodule

module transmitter  #(
                        parameter DataWidth = 8
                     )
                        (

                            input t_clk,
                            input baud_tick,
                            input send,
                            input reset,
                            input load,
                            input [DataWidth+2:0] packet,
                            output Tx,
                            output busy

                        );



reg tx;                        // shows the output of transmitter
reg [DataWidth+2:0] packet_temp;        // to shift data and transmit
reg [DataWidth+2:0] packet_load_ready ; // for storing data to resend if data sent isn't correct 
reg [3:0] b ;                  // for counting no of bits transmitted
reg transmitting;              // can be used to check if transmitting

initial 
begin 
    b =4'd0 ; 
    transmitting = 1'b0;           // initializing them to start transmission 
    tx = 1'b1;                     // initially transmitter is in idle state 
    packet_load_ready = 11'h7ff;   // if load occurs before send this treats as an idle state
end  
       
 
always @(posedge t_clk,posedge reset)
begin
    if(reset)
    begin
        tx           <= 1'b1;
        b            <= 0;
        packet_temp  <= 11'h7ff;
        transmitting <= 1'b0;
    end
    else if(load)
    begin
        packet_temp   <=  packet_load_ready;
        transmitting  <=  1'b1;
    end
    else if (send && ~transmitting)
    begin
            packet_temp       <= packet;
            packet_load_ready <= packet;
            transmitting      <= 1'b1;
    end
    else 
    begin
        if(baud_tick && transmitting )
            begin
                tx                 <=  packet_temp[0];
                packet_temp        <=  {1'b1,packet_temp[DataWidth+2:1]};
                if(b==4'd10)
                begin
                    b              <=    4'd0;
                    transmitting   <=    1'b0;
                end
                else
                b                  <=  b + 4'd1;   
            end
    end
end


assign Tx = tx;
assign busy = ((send && ~transmitting) || transmitting);


endmodule
