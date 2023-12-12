module SPI_Controller (
  input logic clk,            // Clock input
  input logic rst_n,          // Active-low reset input

  // SPI signals
  output logic spi_clk,        // SPI clock
  output logic spi_ss_flash,   // SPI chip select for Flash memory
  output logic spi_ss_seg,     // SPI chip select for 7-segment display
  output logic spi_ss_sr,      // SPI chip select for shift register
  output logic spi_ss_mpu,     // SPI chip select for MPU6000
  output logic spi_mosi,       // SPI master output
  input  logic spi_miso,        // SPI master input

  // Device signals
  output logic [7:0]  flash_data,       // Flash memory data
  output logic [3:0]  seg_display,      // 7-segment display data
  output logic        sr_data,          // Shift register data
  output logic [15:0] mpu_data,        // MPU6000 sensor data

  // Write signals
  input logic       flash_write_enable,      // Signal to trigger Flash write
  input logic [7:0] flash_write_data        // Data to be written to Flash memory
);

// Internal signals
logic [7:0] spi_tx_data;      // Data to be transmitted over SPI
logic [3:0] seg_data_out;     // 7-segment data output

// Internal state machine
typedef enum logic [2:0] {
  IDLE, READ_FLASH, READ_SEG, WRITE_SR, READ_MPU, WRITE_FLASH
} State;

State state, next_state;

// FSM for SPI controller
always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end

// Assign next state based on current state and inputs
always_comb begin
  case (state)
    IDLE        : next_state = READ_FLASH;
    READ_FLASH  : next_state = READ_SEG;
    READ_SEG    : next_state = WRITE_SR;
    WRITE_SR    : next_state = READ_MPU;
    READ_MPU    : next_state = WRITE_FLASH;
    WRITE_FLASH : next_state = IDLE;
    default     : next_state = IDLE;
  endcase
end

// SPI controller logic
always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    spi_tx_data   <= 8'h00;
    flash_data    <= 8'h00;
    seg_data_out  <= 4'h0;
    sr_data       <= 1'b0;
    mpu_data      <= 16'h0000;
  end else begin
    case (state)
      IDLE: begin
        // Do nothing in IDLE state
      end
      
      READ_FLASH: begin
        // Read data from Flash memory
        spi_tx_data <= 8'h03; // Example command for reading data
        flash_data <= spi_rx_data;
      end

      READ_SEG: begin
        // Read data from 7-segment display
        spi_tx_data <= 8'h01; // Example command for reading 7-segment data
        seg_data_out <= spi_rx_data[3:0];
      end
      
      WRITE_SR: begin
        // Write data to shift register
        spi_tx_data <= sr_data;
      end
      
      READ_MPU: begin
        // Read data from MPU6000 sensor
        spi_tx_data <= 8'hAC; // Example command for reading sensor data
        mpu_data <= spi_rx_data;
      end
      
      WRITE_FLASH: begin
        // Write data to Flash memory
        if (flash_write_enable) begin
          spi_tx_data <= flash_write_data;
        end
        flash_data <= spi_rx_data;
      end
    endcase
  end
end

// Assign outputs
assign spi_clk      = clk;
assign spi_ss_flash = (state == READ_FLASH || state == WRITE_FLASH) ? 1'b0 : 1'b1;
assign spi_ss_seg   = (state == READ_SEG) ? 1'b0 : 1'b1;
assign spi_ss_sr    = (state == WRITE_SR) ? 1'b0 : 1'b1;
assign spi_ss_mpu   = (state == READ_MPU) ? 1'b0 : 1'b1;
assign spi_mosi     = spi_tx_data[7];
assign seg_display  = seg_data_out;

endmodule
