package mn.edu.must.sqat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BonusTest {

    @Test
    @DisplayName("B01 all-defs: score49->54; lines 38/39/40/41/42/43/46; present/streak/best defs")
    void B01_allDefs_score49Reaches54_longStreakThenReset() {
        assertEquals(3, DataFlowTargets.bonus(
                new int[]{1, 1, 1, 1, 1, 0, 1}, 8));
    }

    @Test
    @DisplayName("B02 all-defs: score51->54; present40->50(T), best43->53(T), score54->56")
    void B02_allDefs_score51Reaches54_fiveConsecutiveDays() {
        assertEquals(8, DataFlowTargets.bonus(
                new int[]{1, 1, 1, 1, 1}, 5));
    }

    @Test
    @DisplayName("B03 attendance31->32(T); null short-circuit")
    void B03_nullAttendance_coversAttendanceDefinitionToNullBranch_31_32T() {
        assertThrows(IllegalArgumentException.class,
                () -> DataFlowTargets.bonus(null, 1));
    }

    @Test
    @DisplayName("B04 threshold31->32(T); attendance non-null and threshold negative")
    void B04_negativeThreshold_coversThresholdDefinitionToNegativeBranch_31_32T() {
        assertThrows(IllegalArgumentException.class,
                () -> DataFlowTargets.bonus(new int[0], -1));
    }

    @Test
    @DisplayName("B05 attendance31->38(F), present35->50(T), best37->53(F), score51->56")
    void B05_emptyArray_zeroThreshold_coversFalseLoopAndScoreReturn_38_50_53_56() {
        assertEquals(5, DataFlowTargets.bonus(new int[0], 0));
    }

    @Test
    @DisplayName("B06 attendance31->38(T/F), a38->39(F), present35->50(F), best37->53(F), score49->56")
    void B06_allAbsent_belowThreshold_coversInitialDefsToFalseUses_32_38_39_50_53_56() {
        assertEquals(0, DataFlowTargets.bonus(new int[]{0, 0, 0}, 1));
    }

    @Test
    @DisplayName("B07 best43->53(F); streak41->42(F); longest streak stays below five")
    void B07_shortStreakAfterBreak_coversBestUpdatedDefinitionToFalseBranch_42_53() {
        assertEquals(0, DataFlowTargets.bonus(new int[]{1, 1, 0, 1}, 4));
    }

}