module Multiplier #(
    parameter N = 4
) (
    input  wire             clk,
    input  wire             rst_n,

    input  wire             start,
    output reg              ready,

    input  wire [N-1:0]     multiplier,
    input  wire [N-1:0]     multiplicand,
    output reg [2*N-1:0]    product
);

    // Estados da FSM
    localparam IDLE = 2'b00, //Em espera
               BUSY = 2'b01, //Executando a multiplicação
               DONE = 2'b10; // Pronto por 1 ciclo, depois volta para IDLE

    // Registradores internos
    reg [1:0]           state;
    reg [N-1:0]         multiplier_reg;
    reg [2*N-1:0]       multiplicand_reg;   // agora 2*N bits!
    reg [2*N-1:0]       acc;                // acumulador
    localparam CNT_W    = $clog2(N); //log2(N)
    reg [CNT_W-1:0]     count;

    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset síncrono
            state      <= IDLE;
            ready      <= 1'b0;
            product    <= {2*N{1'b0}};
            multiplier_reg <= {N{1'b0}};
            multiplicand_reg  <= {2*N{1'b0}};
            acc        <= {2*N{1'b0}};  
            count        <= {CNT_W{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        // Carrega operandos e inicializa
                        multiplier_reg <= multiplier;
                        multiplicand_reg  <= {{N{1'b0}}, multiplicand};
                        acc        <= {2*N{1'b0}};
                        count        <= {CNT_W{1'b0}};
                        state      <= BUSY;
                    end
                end

                BUSY: begin
                    if (count == N-1) begin
                        // Última iteração: soma o bit N-1 e gera resultado
                        product <= acc + (multiplier_reg[0] ? multiplicand_reg : {2*N{1'b0}}); // Se o último bit do multiplicador (multiplier_reg[0]) for 1, soma o multiplicand_reg no acc uma última vez. Senão, só passa o acc puro para o product.
                        ready   <= 1'b1;   // pulso de ready
                        state   <= DONE;
                    end else begin
                        // Ciclos intermediários: soma condicionada e shift
                        if (multiplier_reg[0])
                            acc <= acc + multiplicand_reg;
                        multiplier_reg <= multiplier_reg >> 1;
                        multiplicand_reg  <= multiplicand_reg << 1;
                        count        <= count + 1'b1;
                    end
                end

                DONE: begin
                    // Retorna ao IDLE, limpando o flag ready
                    ready <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

