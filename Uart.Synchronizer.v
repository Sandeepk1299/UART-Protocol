module stage2_sync
                    (
                        input in,
                        input reset,
                        input clk,
                        output sync
                    );
wire q;


d_ff     stage1  (.d(in),.clk(clk),.reset(reset),.q(q));
d_ff     stage2  (.d(q),.clk(clk),.reset(reset),.q(sync));


endmodule



module d_ff(
                input d,
                input clk,
                input reset,
                output  q
            );
reg Q;
always@(posedge clk,negedge reset)begin
    if(!reset)
        Q <= 0;
    else
        Q <= d;
end
assign q = Q;

endmodule
