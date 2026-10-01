module UART_Protocol #(
                            parameter DataWidth = 8,
                            parameter SamplingWidth = 16
                      )
                        (
                                // inputs to tx
                                input t_clk, 
                                input reset,   // common for both
                                input send,    
                                input load_in, 
                                input [DataWidth-1:0] data_in,
                                // inputs to rx
                                input rx,    
                                input r_clk,
                                // outputs to tx
                                output tx,
                                output busy,
                                // outputs to rx
                                output[DataWidth-1:0] data_out,
                                output done,
                                output load_out

                        );


wire Tx;

UART_TRANSMITTER   #(
                        .DataWidth(DataWidth)
                    )Transmitter(
                                .t_clk(t_clk),
                                .reset(reset),
                                .send(send),
                                .load(load_in),
                                .data_in(data_in),
                                .Tx(Tx),
                                .busy(busy)
                                );

stage2_sync    Tx_synchronisation(
                    .in(Tx),
                    .reset(reset),
                    .clk(r_clk),
                    .sync(tx)

                );


UART_RECEIVER    #(
                        .DataWidth(DataWidth),
                        .SamplingWidth(SamplingWidth)

                  )  Receiver(
                                .r_clk(r_clk),
                                .reset(reset),
                                .rx(rx),
                                .data_out(data_out),
                                .done(done),
                                .load(load_out)                            
                            );

endmodule
