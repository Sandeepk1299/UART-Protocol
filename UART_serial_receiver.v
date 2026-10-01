module top_module(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
); 
    // defining states
    parameter start = 0,data = 1,stop = 2,error = 3,correct = 4,parity = 5;
    
    //to store states
    reg [2:0] state,next_state;
    // to count data bits
    reg [3:0] data_bit_count = 4'd0;
    
    //to store incoming bytes
    reg [7:0] temp;
    
    // parity generation
  //  parity  parity_bit_detector (.in(in),.clk(clk),.reset(reset),.odd(p));
    
    // state transition
    
    always@(*)begin
        case(state)
            start[2:0] : next_state = (!in) ? data[2:0] : start[2:0];
            data[2:0] : next_state = (data_bit_count == 4'd7) ? parity[2:0] : data[2:0];
            parity[2:0] : next_state = (in == ~(^temp)) ? stop[2:0] : error[2:0]; 
            stop[2:0] : next_state = (in) ? correct[2:0] : error[2:0];
            correct[2:0] : next_state = (!in) ? data[2:0] : start[2:0];
            error[2:0] : next_state = (in) ? start[2:0] : error[2:0];
            default : next_state = start[2:0];
        endcase
    end
    
    //state assigning
    
    always@(posedge clk)
        begin
            if(reset)
                state <= start[2:0];
            else 
                state <= next_state;
        end
    
    // bit counter
    always@(posedge clk)begin
        if(reset)begin
            data_bit_count <= 4'd0;
            temp <= 8'hff;
        end
        else if(state==data[2:0])begin
            temp[data_bit_count] <= in;
           	data_bit_count <= data_bit_count + 4'd1;
        end
        else
            data_bit_count <= 4'd0;
    end
    
    
    // output assigning
    assign done = (state==correct[2:0]);
	assign out_byte = temp;
    
endmodule

