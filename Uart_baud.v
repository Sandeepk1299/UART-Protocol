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
