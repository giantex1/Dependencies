//
//  Created by Brian Ganninger on 9/30/16.
//  Copyright © 2016 Atlassian. All rights reserved.
//

import XCTest
import Sparkle

class PRGTestProgressiveUpdates: XCTestCase
{
	// MARK: - Tests -
	
	func testUpdaterBasics()
	{
		let updateHelper = PRGUpdateHelper()
		let updater = updateHelper.newSparkleUpdater()
		let defaults = UserDefaults.standard
		let currentGroup = defaults.value(forKey: PRGUpdateGroupDefaultsKey)
		let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
		
		// test convenience method for setup
		XCTAssertNotNil(updater)
		XCTAssertNotNil(updateHelper)
		XCTAssertEqual(updater.delegate as? PRGUpdateHelper, updateHelper)
		
		// test convenience accessor for assigned group
		let expectedGroup = 2
		defaults.setValue(expectedGroup, forKey:PRGUpdateGroupDefaultsKey)
		XCTAssertEqual(expectedGroup, PRGUpdateHelper.currentUpdateGroup())
		
		// test the 'auto reset' group assignment
		defaults.removeObject(forKey: PRGUpdateGroupDefaultsKey)
		defaults.removeObject(forKey: PRGUpdateVersionDefaultsKey)
		defaults.removeObject(forKey: PRGUpdateExemptionDefaultsKey)
		XCTAssertNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertNil(defaults.object(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNil(defaults.object(forKey: PRGUpdateExemptionDefaultsKey))
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		
		defaults.removeObject(forKey: PRGUpdateGroupDefaultsKey)
		XCTAssertNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		defaults.set(404, forKey:PRGUpdateExemptionDefaultsKey)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		
		defaults.removeObject(forKey: PRGUpdateVersionDefaultsKey)
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertNil(defaults.object(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		
		let assignedGroup = defaults.integer(forKey: PRGUpdateGroupDefaultsKey)
		defaults.setValue(0.9, forKey:PRGUpdateVersionDefaultsKey)
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), assignedGroup)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 1)
		defaults.setValue(0.9, forKey:PRGUpdateVersionDefaultsKey)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		
		defaults.setValue(0.9, forKey:PRGUpdateVersionDefaultsKey)
		defaults.removeObject(forKey: PRGUpdateExemptionDefaultsKey)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))
		XCTAssertNotNil(defaults.object(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertLessThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 5)
		XCTAssertGreaterThanOrEqual(defaults.integer(forKey: PRGUpdateGroupDefaultsKey), 0)
		XCTAssertEqual(defaults.integer(forKey: PRGUpdateExemptionDefaultsKey), 2)
		
		defaults.setValue(expectedGroup, forKey:PRGUpdateGroupDefaultsKey)
		defaults.setValue(currentAppVersion, forKey:PRGUpdateVersionDefaultsKey)
		PRGUpdateHelper.resetUpdateGrouping()
		XCTAssertEqual(expectedGroup, defaults.integer(forKey: PRGUpdateGroupDefaultsKey))
		XCTAssertEqual(currentAppVersion as? String, defaults.string(forKey: PRGUpdateVersionDefaultsKey))

		defaults.setValue(currentGroup, forKey:PRGUpdateGroupDefaultsKey)
	}
	
	func testSparkleDelegate()
	{
		let updateHelper = PRGUpdateHelper()
		let updater = updateHelper.newSparkleUpdater()
		
		// optional update suppression
		updateHelper.canUpdate = true
		XCTAssertTrue(updateHelper.updaterMayCheck(forUpdates: updater))
		updateHelper.canUpdate = false
		XCTAssertFalse(updateHelper.updaterMayCheck(forUpdates: updater))
		
		// feed URL override
		let defaults = UserDefaults.standard
		let expectedGroup = 2
		let currentGroup = defaults.value(forKey: PRGUpdateGroupDefaultsKey)
		defaults.setValue(expectedGroup, forKey:PRGUpdateGroupDefaultsKey)
		XCTAssertEqual("https://www.sourcetreeapp.com/update/SparkleAppcastGroup2.xml",
		               updateHelper.feedURLString(for: updater))
		defaults.setValue(currentGroup, forKey:PRGUpdateGroupDefaultsKey)
	}
	
	func testUpdateGroupsAccuracy()
	{
		let uuidIterations: Double = 100000
		let uuidBase: Double = uuidIterations / 100
		let allowedVariance = 1.0
		
		var group0Total = 0.0
		var group1Total = 0.0
		var group2Total = 0.0
		var group3Total = 0.0
		var group4Total = 0.0
		var group5Total = 0.0
		
		var loopIndex: Double = 0
		while (loopIndex < uuidIterations)
		{
			let aGroup = PRGUpdateHelper.group(for: UUID())
			
			switch aGroup
			{
				case 0:
					group0Total += 1
					break
				case 1:
					group1Total += 1
					break
				case 2:
					group2Total += 1
					break
				case 3:
					group3Total += 1
					break
				case 4:
					group4Total += 1
					break
				case 5:
					group5Total += 1
					break
				default:
					break
			}
			
			loopIndex += 1
		}
		
		XCTAssertEqualWithAccuracy(round((group0Total / uuidBase)), 5, accuracy:allowedVariance)
		XCTAssertEqualWithAccuracy(round((group1Total / uuidBase)), 10, accuracy:allowedVariance)
		XCTAssertEqualWithAccuracy(round((group2Total / uuidBase)), 10, accuracy:allowedVariance)
		XCTAssertEqualWithAccuracy((round(group3Total / uuidBase)), 25, accuracy:allowedVariance)
		XCTAssertEqualWithAccuracy((round(group4Total / uuidBase)), 25, accuracy:allowedVariance)
		XCTAssertEqualWithAccuracy((round(group5Total / uuidBase)), 25, accuracy:allowedVariance)
	}
	
	func testFeedURLTransformations()
	{
		let updateHelper = PRGUpdateHelper()
		let appcastSlug = "Appcast.xml"
		let defaultURL = "https://www.sourcetreeapp.com/update/SparkleAppcast.xml"
		
		// URL checks
		let group0 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup0.xml")
		XCTAssertEqual(group0, updateHelper.feedURL(forGroup: 0))
		let group1 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup1.xml")
		XCTAssertEqual(group1, updateHelper.feedURL(forGroup: 1))
		let group2 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup2.xml")
		XCTAssertEqual(group2, updateHelper.feedURL(forGroup: 2))
		let group3 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup3.xml")
		XCTAssertEqual(group3, updateHelper.feedURL(forGroup: 3))
		let group4 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup4.xml")
		XCTAssertEqual(group4, updateHelper.feedURL(forGroup: 4))
		let group5 = defaultURL.replacingOccurrences(of: appcastSlug, with:"AppcastGroup5.xml")
		XCTAssertEqual(group5, updateHelper.feedURL(forGroup: 5))
		
		// bounds checks
		XCTAssertEqual(defaultURL, updateHelper.feedURL(forGroup: -1))
		XCTAssertEqual(defaultURL, updateHelper.feedURL(forGroup: 54986))
	}
	
	func testValueTransformer()
	{
		let groupTransformer = PRGGroupPercentageTransformer.init()
		
		// actual groupings
		XCTAssertEqual(groupTransformer.transformedValue(0) as? NSNumber, 5 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(1) as? NSNumber, 15 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(2) as? NSNumber, 25 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(3) as? NSNumber, 50 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(4) as? NSNumber, 75 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(5) as? NSNumber, 100 as NSNumber)
		
		// bounds checks
		XCTAssertEqual(groupTransformer.transformedValue(-1) as? NSNumber, -1 as NSNumber)
		XCTAssertEqual(groupTransformer.transformedValue(54986) as? NSNumber, -1 as NSNumber)
	}
}
