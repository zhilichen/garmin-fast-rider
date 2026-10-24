import Toybox.Test;
import Toybox.Position;

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
    return true;
}

(:test)
function gearTest(logger) {
    Test.assertEqual(RideMath.gears(2, 7), "2 / 7");
    Test.assertEqual(RideMath.gears(null, null), "-- / --");
    Test.assertEqual(RideMath.gears(0, 7), "-- / 7");
    Test.assertEqual(RideMath.gradeText(null), "--");
    Test.assertEqual(RideMath.gradeText(4.2), "+4.2");
    Test.assertEqual(RideMath.gradeText(-6.5), "-6.5");
    Test.assertEqual(RideMath.gradeText(-0.001), "+0.0");
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
