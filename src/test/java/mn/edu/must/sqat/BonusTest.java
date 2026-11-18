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

}