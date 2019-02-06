library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_tb is
end top_tb;

architecture Bench of top_tb is

  constant PERIOD : time := 10 ns;
  signal CLOCK : std_logic := '0';
  signal STOP_CLOCK : boolean := false;

  signal OKAY : boolean := true;

  signal a, b, c : natural;

begin

  clk : process
  begin
    while not STOP_CLOCK loop
      wait for PERIOD / 2;
      CLOCK <= not CLOCK;
    end loop;
    wait;
  end process clk;

  main : process
  begin
    a <= 1;
    wait until falling_edge(CLOCK);

    b <= 2;
    wait until falling_edge(CLOCK);

    c <= a + b;
    wait until falling_edge(CLOCK);

    if c /= 3 then
      OKAY <= false;
    end if;

    wait for 100 ns;

    STOP_CLOCK <= true;

    assert OKAY report "Testbench failed" severity failure;

    wait;
  end process main;

end Bench;
