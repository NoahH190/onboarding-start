import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.result import TestFailure

async def wait_for_edges(dut, signal, num_edges, edge_type='rising'):
    """Wait for a number of rising or falling edges on a signal."""
    times = []
    for _ in range(num_edges):
        if edge_type == 'rising':
            await RisingEdge(signal)
        else:
            await FallingEdge(signal)
        times.append(dut._env.now)
    return times

@cocotb.test()
async def test_pwm_frequency_and_duty_cycle(dut):
    """Test PWM frequency and duty cycle at 0%, 50%, and 100%."""
    clk_period_ns = 10  
    dut.rst_n <= 0
    await Timer(100, units='ns')
    dut.rst_n <= 1

    await Timer(1000, units='ns')

    times = await wait_for_edges(dut, dut.uo_out, 2, 'rising')
    period_ns = times[1] - times[0]
    freq = 1e9 / period_ns
    assert 2970 <= freq <= 3030, f"Frequency out of range: {freq} Hz"

    t_rise1 = times[0]
    await FallingEdge(dut.uo_out)
    t_fall = dut._env.now
    high_time = t_fall - t_rise1
    duty = (high_time / period_ns) * 100
    assert 49 <= duty <= 51, f"Duty cycle out of range: {duty}%"


    await Timer(1000, units='ns')
    assert dut.uo_out.value == 0, "PWM output should be low at 0% duty"

    await Timer(1000, units='ns')
    assert dut.uo_out.value == 1, "PWM output should be high at 100% duty"