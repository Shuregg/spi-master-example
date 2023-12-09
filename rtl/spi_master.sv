`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.11.2023 21:28:33
// Design Name: 
// Module Name: SPI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Variant #2. SPI.
// Modules used: W25Q16 Flash memory, 7-segment indicator, 74HC595 shift register, MPU6000 sensor.
// Tasks for testbench:
// 1. Read 4 bytes of data from Flash memory W25Q16.
// 2. Output the received data to eight 7-segment indicators connected via shift registers 74HC595.
// 3. Write data to Flash memory W25Q16 at any available address.
// 4. Read data from the W25Q16 Flash memory at any available address using the Fast Read command.
// 5. Display the received data on 7-segment indicators.
// 6. Read data from MPU6000 at addresses 114-117.
// 7. Display the received data on 7-segment indicators.
// Connect the 7-segment indicators according to the serial scheme, the other devices - according to the parallel scheme.

// MODE: CPOL = 0, CPHA = 0.

typedef enum logic [2:0] 
{
    IDLE            =   3'b000
    RECEIVE         =   3'b001, 
    TRANCIEVE       =   3'b010, 
} State;


module spi_master
(
    //SPI Interface
    input   logic           MISO_i,                         //Master inpur Slave Output
    output  logic           SCLK_o,                         //Serial Clock for peripherial devices
    output  logic           RST_o                           //Global reset for peripherial devices
    output  logic   [2:0]   SS_o,                           //Slave Select (Flash, Shift register, Giroscope)
    output  logic           MOSI_o,                         //Master Output Slave Input

    output  logic           sr_out_en_o,                     //Shift register output enable    
    output  logic           sr_we_o,
    output  logic           sr_wd_o,

    //Controller Interface          
    input   logic           clk_i,                          //base clock
    input   logic           rst_i,                          //Syncr global Reset
    input   logic   [2:0]   SS_i,                           //Slave Select (Flash, Shift register, Giroscope)
    input   logic           transaction_started_i,

    input   logic   [7:0]   flash_rw_data_size_i,
    input   logic           MOSI_i,

    input   logic           sr_out_en_i,                     //Shift register output enable 
    input   logic           sr_we_i,
    input   logic           sr_wd_i
    );
    
    State logic [2:0] state, logic [2:0] state_next;
    
    // logic [255:0] tx_data;    //transmitted data
    logic [255:0] rx_data;          //received data
    
    logic [8:0] bit_counter;        //Counter for bit receive/send


    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            SS_o        <= 3'b0;
            sr_out_en_o <= 1'b0;
            sr_we_o     <= 1'b0;    
            sr_out_en_o <= 1'b0;
            state       <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    case(SS_i)
                        3'b001 :    state <= TRANCIEVE;         //Giroscope
                        3'b010 :    state <= TRANCIEVE;         //Shift Reg
                        3'b100 :    state <= TRANCIEVE;         //Flash
                        default:    state <= IDLE;
                    endcase
                end
                TRANCIEVE: begin
                    if(MISO_i === 1'bz) begin
                        MOSI_o  <= MOSI_i;
                    end else begin
                        MOSI_o  <= 1'bz;
                        sr_we_o <= 1'b1;
                        sr_wd_o <= sr_wd_i;
                        state   <= RECEIVE;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            SS_o        <= 3'b0;
            sr_out_en_o <= 1'b0;    
        end else begin

        end
    end
    // always_ff @ (posedge clk_i) begin
    //     if(rst_i) begin
    //         state       <=  RESET;            
    //     end else begin
    //         case(state)
    //             RESET:
    //                 state   <=   IDLE;
    //             IDLE:
    //                 case(transaction_started_i)
    //                     1'b0:   state   <=   IDLE;
    //                     1'b1:   state   <=   SHIFT;
    //                 endcase
    //             SHIFT:

    //             LOAD:

    //             UNLOAD:

    //         endcase
            
    //     end
    // end

    // always_comb begin// : FSM
    //     case(state)
    //         RESET:  begin
    //             MISO_i      <=  1'b0;
    //             MOSI_o      <=  1'b1;
    //             tx_data     <=  8'b0;
    //             rx_data     <=  8'b0;
    //             bit_counter <=  10'b0;
    //         end
    //         IDLE:   begin
    //             case()
    //                 2'b00:
    //                     state_next  <= IDLE;
    //                 2'b00: begin       //FLASH

    //                 end

    //                 2'b00: begin

    //                 end

    //                 2'b00: begin

    //                 end

    //                 default: begin
    //                     state_next  <= IDLE;
    //                 end

    //             endcase
    //         end

    //     endcase
    // end

endmodule
 
