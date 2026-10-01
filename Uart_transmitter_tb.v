`timescale 1ns/1ps
`default_nettype none

module Uart_transmitter_tb;

// parameters

parameter DataWidth = 8;


// inputs 

reg t_clk;
reg reset;
reg send;   // send is asserted before every data sent
reg load;   // load has a higher priority than send
reg [DataWidth-1:0] data_in;


// outputs

wire Tx;
wire busy;

// Instantiation

UART_TRANSMITTER   # (
                            .DataWidth(DataWidth)
                        )
                    DUT (
                            .t_clk(t_clk),
                            .reset(reset),
                            .send(send),
                            .load(load),
                            .data_in(data_in),
                            .Tx(Tx),
                            .busy(busy)
                        );

// getting baudtick

wire baud_tick;
assign baud_tick = DUT.B_T.baud_tick;

// clock

initial t_clk = 0;
always #8 t_clk <= ~t_clk;

// Scoreboard

integer pass_cnt = 0;
integer fail_cnt = 0;


// check any output 

task check_flag;
        input exp;
        input actual;
        begin
            if(actual==exp)begin
                $display("\nExpected flag : %0b , Actual flag : %0b",exp,actual);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("\nExpected flag : %0b , Actual flag : %0b",exp,actual);
                fail_cnt = fail_cnt + 1;
            end
        end
endtask
            
            


// Tasks !!


// wait for N baudticks
task wait_N_baud;
        input integer N;
        integer count;
        begin
            count = 0;
            while(count<N)begin
                @(posedge baud_tick);
                count = count + 1;
            end
        end   
endtask

// applying reset
task apply_reset;
        begin
            reset <= 1;
            repeat(64) @(posedge t_clk);
            reset <= 0;
        end
endtask

// sending data correctly
task send_data;
        input [DataWidth-1 : 0] data;
        begin
            @(negedge t_clk);
            send <= 1'b1;
            data_in <= data;
            @(posedge t_clk);
            send <= 1'b0;
        end
endtask

// sending data without send signal

task send_data_s;
        input [DataWidth-1 : 0] data;
        begin
            data_in <= data;
        end
endtask


// Main test sequence 

initial begin

$dumpfile("Uart_transmitter.vcd");
$dumpvars(0,Uart_transmitter_tb);

apply_reset;
send = 1'b0;
load = 1'b0;
data_in = 8'h0;

$display("\n------> TX TEST SEQUENCE BEGIN <--------");


// Test - 1 simple data transmission
$display("\n Test - 1 simple data transmission");
send_data(8'h24);

// Test - 2 send data without send signal
$display("\n Test - 2 send data without send signal");
send_data_s(8'h45);
wait_N_baud(15);
// resending the same data with send signal again
send_data(8'h45);
wait_N_baud(15);

// Test - 3 reset during send
$display("\nTest - 3 reset during send");
fork
    begin
        send_data(8'h22);
        wait_N_baud(11);
    end
    begin
        wait_N_baud(5);
        apply_reset;
    end
join

// same data is send again without reset
send_data(8'h22);
wait_N_baud(15);


// Test - 4 Continuous transmission one after the other
$display("\nTest - 4 Continuous transmission one after the other");
send_data(8'h00);wait_N_baud(11);
send_data(8'h01);wait_N_baud(11);
send_data(8'h80);wait_N_baud(11);
send_data(8'hff);wait_N_baud(11);

// Test - 5 Long Idle state
$display("\nLong idle state");
apply_reset;
wait_N_baud(44);
check_flag(1'b0,busy);$display("\n since busy = 0 we are in idle state");

// Test - 6 Sending data soon after idle data transmission
$display("\nTest - 6 Sending data soon after idle data transmission");
send_data(8'h55);wait_N_baud(11);
send_data(8'haa);wait_N_baud(11);
send_data(8'h11);wait_N_baud(11);
send_data(8'h88);wait_N_baud(11);

// Test - 7 New Data Sent without completing old data transmission
// Here data sent next will be rejected since transmitter was busy
$display("\nTest - 7 New Data Sent without completing old data transmission");
send_data(8'h07);wait_N_baud(5);
send_data(8'h25);wait_N_baud(3);
send_data(8'h50);


// Test - 8 Checking data retransmission using load
$display("\nTest - 8 Checking data retransmission using load");
send_data(8'h35);wait_N_baud(5);
apply_reset;
check_flag(1'b0,busy);
$display("\nWe went back to idle state due to reset");
load = 1;
wait_N_baud(1);
load = 0;
check_flag(1'b1,busy);
$display("\n We have started retransmission of data so busy = 1");



// Results 

$display("\n-------------> RESULTS <--------------");
$display("\n pass count = %0d , fail count = %0d ",pass_cnt,fail_cnt);

#50000;
$finish;

end


// Catching runtime error
initial begin
    #5000000000;
    $display("\n Runtime error");
    $finish;
end

endmodule







