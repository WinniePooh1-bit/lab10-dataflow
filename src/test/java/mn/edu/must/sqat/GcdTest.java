package mn.edu.must.sqat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GcdTest {

    @Test
    @DisplayName("G01 lines 13 -> 15(F) -> 20; DU x13->20 and y13->15(F)")
    void gcd_zeroSecondArgument_coversEntryToExitPairs_13_15_20() {
        assertEquals(7, DataFlowTargets.gcd(7, 0));
    }

    @Test
    @DisplayName("G02 loop-carried DU pairs: x17->16/20, y13/18->15/16/17, tmp16->18")
    void gcd_twoIterations_coversLoopCarriedPairs_15_16_17_18_20() {
        assertEquals(4, DataFlowTargets.gcd(12, 8));
    }
}