`default_nettype none

module spi_module (
    input  wire clk,
    input  wire rst_n,
    input  wire mosi,
    output wire miso,
    input  wire sclk,
    input  wire cs_n,
    output reg [7:0] rx_data,
    input  wire [7:0] tx_data,
    output reg rx_done,
    input  wire tx_start
);

    reg [2:0] bit_cnt;
    reg [7:0] rx_shift;
    reg [7:0] tx_shift;
    reg tx_active;

    // Receive logic
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt  <= 3'd0;
            rx_shift <= 8'd0;
            rx_done  <= 1'b0;
        end else if (!cs_n) begin
            rx_shift <= {rx_shift[6:0], mosi};
            bit_cnt  <= bit_cnt + 1'b1;
            if (bit_cnt == 3'd7) begin
                rx_data <= {rx_shift[6:0], mosi};
                rx_done <= 1'b1;
                bit_cnt <= 3'd0;
            end else begin
                rx_done <= 1'b0;
            end
        end else begin
            bit_cnt  <= 3'd0;
            rx_done  <= 1'b0;
        end
    end

    // Transmit logic
    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 8'd0;
            tx_active <= 1'b0;
        end else if (tx_start && !cs_n) begin
            tx_shift <= tx_data;
            tx_active <= 1'b1;
        end else if (tx_active && !cs_n) begin
            tx_shift <= {tx_shift[6:0], 1'b0};
            if (bit_cnt == 3'd7) begin
                tx_active <= 1'b0;
            end
        end else if (cs_n) begin
            tx_active <= 1'b0;
        end
    end

    assign miso = tx_active ? tx_shift[7] : 1'bz;

endmodule