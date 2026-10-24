import Toybox.Test;
import Toybox.Position;

(:test)
function measuredHistoryTest(logger) {
    var h = new ElevationHistory();
    h.update(0, 100, true, 0);
    h.update(10, 110, true, 1000);
    assertNear(h.sample(5)[0], 105.0);
    Test.assert(h.sample(-1) == null && h.sample(11) == null);
    // Missing altitude breaks the measured line, rather than borrowing GPX.
    h.update(15, null, true, 2000);
    h.update(20, 120, true, 3000);
    Test.assert(h.sample(15) == null);
    h.update(24, 124, true, 3500);
    assertNear(h.sample(22)[0], 122.0);
    h.update(24, 124, false, 4000);
    h.update(30, 130, true, 5000);
    Test.assert(h.sample(27) == null);
    h.update(40, 140, true, 12000);
    Test.assert(h.sample(35) == null);
    // Even a pause/resume between consecutive compute calls breaks the line.
    h.breakSample();
    h.update(45, 145, true, 12500);
    Test.assert(h.sample(42) == null);
    h.update(2, 99, true, 13000);
    Test.assertEqual(h.points.size(), 1);
    assertNear(h.sample(2)[0], 99.0);
    Test.assert(h.sample(1) == null && h.sample(3) == null);
    var bounds = h.window();
    assertNear(bounds[1], 2.0);
    assertNear(bounds[1]-bounds[0], 100.0);
    Test.assert(bounds[3]-bounds[2] >= 40);
    h.update(null, null, true, 14000);
    Test.assert(h.distance == null && h.altitude == null);
    return true;
}

(:test)
function boundedHistoryTest(logger) {
    var h = new ElevationHistory();
    for (var i = 0; i < 400; i += 1) { h.update(i*5.0, 100+(i%23)*2.0, true, i*1000); }
    Test.assert(h.points.size() <= 160);
    assertNear(h.points[0][0], 0.0);
    assertNear(h.points[h.points.size()-1][0], 1995.0);
    // Compaction keeps actual samples, never averaged or planned elevations.
    for (var i = 0; i < h.points.size(); i += 1) {
        var p = h.points[i];
        assertNear(p[1], 100+((p[0]/5).toNumber()%23)*2.0);
    }
    Test.assert(h.sample(1996) == null);
    h.reset();
    Test.assertEqual(h.points.size(), 0);
    Test.assert(h.sample(0) == null);
    return true;
}

function assertNear(actual, expected) {
    // Monkey C assertEqual also compares numeric types; interpolation is Float.
    Test.assert(actual >= expected-0.05 && actual <= expected+0.05);
}

(:test)
function zonesTest(logger) {
    var limits = [137.5, 187.5, 225, 262.5, 300, 375];
    Test.assertEqual(RideMath.zone(null, limits), 0);
    Test.assertEqual(RideMath.zone(0, limits), 1);
    Test.assertEqual(RideMath.zone(225, limits), 3);
    Test.assertEqual(RideMath.zone(226, limits), 4);
    Test.assertEqual(RideMath.zone(500, limits), 7);
    Test.assertEqual(RideMath.zone(152, [114, 133, 152, 171]), 3);
    Test.assertEqual(RideMath.zone(153, [114, 133, 152, 171]), 4);
    return true;
}

(:test)
function timeTest(logger) {
    Test.assertEqual(RideMath.duration(0), "0:00:00");
    Test.assertEqual(RideMath.duration(3661000), "1:01:01");
    Test.assertEqual(RideMath.duration(36000000), "10:00:00");
    Test.assertEqual(RideMath.lapDuration(null), "--:--");
    Test.assertEqual(RideMath.lapDuration(0), "00:00");
    Test.assertEqual(RideMath.lapDuration(312000), "05:12");
    Test.assertEqual(RideMath.lapDuration(3661000), "1:01:01");
    return true;
}

(:test)
function gearTest(logger) {
    Test.assertEqual(RideMath.gears(2, 7), "2/7");
    Test.assertEqual(RideMath.gears(null, null), "--/--");
    Test.assertEqual(RideMath.gears(0, 7), "--/7");
    Test.assertEqual(RideMath.gradeText(null), "--");
    Test.assertEqual(RideMath.gradeText(4.2), "+4.2");
    Test.assertEqual(RideMath.gradeText(-6.5), "-6.5");
    Test.assertEqual(RideMath.gradeText(-0.001), "+0.0");
    return true;
}

(:test)
function lapStatsTest(logger) {
    var s = new LapStats();
    s.started(100000);
    s.update(101000, 200, true);
    Test.assert(!s.synced && s.timeMs == null && s.averagePower == null);
    // The next native boundary is the first reliable start after a mid-ride load.
    s.begin(102000, 200);
    s.update(103000, 200, true);
    Test.assertEqual(s.timeMs, 1000);
    assertNear(s.averagePower, 200.0);
    s.update(104000, 0, true);
    s.update(105000, 0, true);
    assertNear(s.averagePower, 100.0);
    // Pause/stop and resume/start must preserve this native lap.
    s.update(105000, 800, false);
    s.started(105000);
    s.update(105000, 200, true);
    s.update(106000, 200, true);
    Test.assertEqual(s.timeMs, 4000);
    assertNear(s.averagePower, 125.0);
    // Missing power and long gaps are not silently filled with zero or stale power.
    s.update(107000, null, true);
    s.update(108000, 400, true);
    s.update(120000, 400, true);
    assertNear(s.averagePower, 125.0);
    // Every manual/auto boundary clears only the lap accumulator.
    s.begin(120000, 0);
    s.update(121000, 0, true);
    Test.assertEqual(s.timeMs, 1000);
    assertNear(s.averagePower, 0.0);
    s.update(0, 150, true);
    Test.assert(s.synced && s.timeMs == 0 && s.averagePower == null);
    s.update(1000, 150, true);
    assertNear(s.averagePower, 150.0);
    s.breakSample();
    s.update(0, 200, true);
    Test.assert(s.synced && s.timeMs == 0 && s.averagePower == null);
    return true;
}

(:test)
function gradeTest(logger) {
    var e = new GradeEstimator();
    Test.assert(e.update(0.0, 100.0, 0) == null);
    for (var i = 1; i < 4; i += 1) { Test.assert(e.update(i*5.0, 100+i*0.25, i*1000) == null); }
    assertNear(e.update(20.0, 101.0, 4000), 5.0);
    assertNear(e.update(25.0, 101.25, 5000), 5.0);
    // A stopped bike expires its estimate, rather than keeping a stale grade.
    Test.assert(e.update(25.0, 101.25, 21001) == null);
    assertNear(e.update(45.0, 100.25, 25001), -5.0);
    Test.assert(e.update(null, 100.0, 26000) == null);
    Test.assert(e.update(0.0, 100.0, 27000) == null);
    assertNear(e.update(20.0, 100.0, 29000), 0.0);
    // Activity reset and bad altitude jumps must discard history.
    Test.assert(e.update(1.0, 100.0, 30000) == null);
    Test.assert(e.update(21.0, 200.0, 31000) == null);
    return true;
}

(:test)
function courseTest(logger) {
    assertNear(RideMath.elevation(0), CourseData.ELEVATIONS[0]);
    assertNear(RideMath.elevation(CourseData.LENGTH), CourseData.ELEVATIONS[CourseData.ELEVATIONS.size()-1]);
    assertNear(RideMath.elevation(-100), CourseData.ELEVATIONS[0]);
    assertNear(RideMath.elevation(CourseData.LENGTH+100), CourseData.ELEVATIONS[CourseData.ELEVATIONS.size()-1]);
    var halfway = (CourseData.DISTANCES[0] + CourseData.DISTANCES[1]) / 2.0;
    assertNear(RideMath.elevation(halfway), (CourseData.ELEVATIONS[0]+CourseData.ELEVATIONS[1])/2.0);
    var tracker = new CourseTracker();
    tracker.update(null);
    Test.assert(tracker.distance == null);
    tracker.update(new Position.Location({:latitude=>CourseData.POINTS[0][0], :longitude=>CourseData.POINTS[0][1], :format=>:degrees}));
    Test.assert(tracker.distance != null && tracker.distance < 10);
    tracker.update(new Position.Location({:latitude=>0.0, :longitude=>0.0, :format=>:degrees}));
    Test.assert(tracker.distance == null);
    Test.assertEqual(tracker.state, "OFF COURSE");
    return true;
}
