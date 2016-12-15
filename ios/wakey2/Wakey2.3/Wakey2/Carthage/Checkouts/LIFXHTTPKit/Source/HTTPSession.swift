//
//  Created by Tate Johnson on 13/06/2015.
//  Copyright (c) 2015 Tate Johnson. All rights reserved.
//

import Foundation

public class HTTPSession {
	public static let defaultBaseURL: NSURL = NSURL(string: "https://api.lifx.com/v1/")!
	public static let defaultUserAgent: String = "LIFXHTTPKit/\(LIFXHTTPKitVersionNumber)"
	public static let defaultTimeout: NSTimeInterval = 5.0

	public let baseURL: NSURL
	public let delegateQueue: dispatch_queue_t
	public let URLSession: NSURLSession

	private let operationQueue: NSOperationQueue

	public init(accessToken: String, delegateQueue: dispatch_queue_t = dispatch_queue_create("com.tatey.lifx-http-kit.http-session", DISPATCH_QUEUE_SERIAL), baseURL: NSURL = HTTPSession.defaultBaseURL, userAgent: String = HTTPSession.defaultUserAgent, timeout: NSTimeInterval = HTTPSession.defaultTimeout) {
		self.baseURL = baseURL
		self.delegateQueue = delegateQueue

		let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
		configuration.HTTPAdditionalHeaders = ["Authorization": "Bearer \(accessToken)", "Accept": "appplication/json", "User-Agent": userAgent]
		configuration.timeoutIntervalForRequest = timeout
		URLSession = NSURLSession(configuration: configuration)

		operationQueue = NSOperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
	}

	public func lights(selector: String = "all", completionHandler: ((request: NSURLRequest, response: NSURLResponse?, lights: [Light], error: NSError?) -> Void)) {
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent("lights/\(selector)"))
		request.HTTPMethod = "GET"
		addOperationWithRequest(request) { (data, response, error) in
			if let error = error ?? self.validateResponseWithExpectedStatusCodes(response, statusCodes: [200]) {
				completionHandler(request: request, response: response, lights: [], error: error)
			} else {
				let (lights, error) = self.dataToLights(data)
				completionHandler(request: request, response: response, lights: lights, error: error)
			}
		}
	}

	public func setLightsPower(selector: String, power: Bool, duration: Float, completionHandler: ((request: NSURLRequest, response: NSURLResponse?, results: [Result], error: NSError?) -> Void)) {
		print("`setLightsPower:power:duration:completionHandler:` is deprecated and will be removed in a future version. Use `setLightsState:power:color:brightness:duration:completionHandler:` instead.")
		setLightsState(selector, power: power, duration: duration, completionHandler: completionHandler)
	}

	public func setLightsColor(selector: String, color: String, duration: Float, powerOn: Bool, completionHandler: ((request: NSURLRequest, response: NSURLResponse?, results: [Result], error: NSError?) -> Void)) {
		print("`setLightsColor:color:duration:powerOn:completionHandler:` is deprecated and will be removed in a future version. Use `setLightsState:power:color:brightness:duration:completionHandler:` instead.")
		setLightsState(selector, color: color, power: powerOn, duration: duration, completionHandler: completionHandler)
	}

	public func setLightsState(selector: String, power: Bool? = nil, color: String? = nil, brightness: Double? = nil, duration: Float, completionHandler: ((request: NSURLRequest, response: NSURLResponse?, results: [Result], error: NSError?) -> Void)) {
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent("lights/\(selector)/state"))
		var parameters: [String : AnyObject] = ["duration": duration]
		if let power = power {
			parameters["power"] = power ? "on" : "off"
		}
		if let color = color {
			parameters["color"] = color
		}
		if let brightness = brightness {
			parameters["brightness"] = brightness
		}
		request.HTTPMethod = "PUT"
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(parameters, options: [])
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		addOperationWithRequest(request) { (data, response, error) in
			if let error = error ?? self.validateResponseWithExpectedStatusCodes(response, statusCodes: [200, 207]) {
				completionHandler(request: request, response: response, results: [], error: error)
			} else {
				let (results, error) = self.dataToResults(data)
				completionHandler(request: request, response: response, results: results, error: error)
			}
		}
	}

	public func scenes(completionHandler: ((request: NSURLRequest, response: NSURLResponse?, scenes: [Scene], error: NSError?) -> Void)) {
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent("scenes"))
		request.HTTPMethod = "GET"
		addOperationWithRequest(request) { (data, response, error) in
			if let error = error ?? self.validateResponseWithExpectedStatusCodes(response, statusCodes: [200]) {
				completionHandler(request: request, response: response, scenes: [], error: error)
			} else {
				let (scenes, error) = self.dataToScenes(data)
				completionHandler(request: request, response: response, scenes: scenes, error: error)
			}
		}
	}

	public func setScenesActivate(selector: String, duration: Float, completionHandler: ((request: NSURLRequest, response: NSURLResponse?, results: [Result], error: NSError?) -> Void)) {
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent("scenes/\(selector)/activate"))
		let parameters = ["duration", duration]
		request.HTTPMethod = "PUT"
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(parameters, options: [])
		addOperationWithRequest(request) { (data, response, error) in
			if let error = error ?? self.validateResponseWithExpectedStatusCodes(response, statusCodes: [200, 207]) {
				completionHandler(request: request, response: response, results: [], error: error)
			} else {
				let (results, error) = self.dataToResults(data)
				completionHandler(request: request, response: response, results: results, error: error)
			}
		}
	}

	// MARK: Helpers

	private func addOperationWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
		let operation = HTTPOperation(URLSession: URLSession, delegateQueue: delegateQueue, request: request, completionHandler: completionHandler)
		operationQueue.operations.first?.addDependency(operation)
		operationQueue.addOperation(operation)
	}

	private func validateResponseWithExpectedStatusCodes(response: NSURLResponse?, statusCodes: [Int]) -> NSError? {
		guard let response = response as? NSHTTPURLResponse else {
			return nil
		}

		if statusCodes.contains(response.statusCode) {
			return nil
		}

		switch (response.statusCode) {
		case 401:
			return Error(code: .Unauthorized, message: "Bad access token").toNSError()
		case 403:
			return Error(code: .Forbidden, message: "Permission denied").toNSError()
		case 429:
			return Error(code: .TooManyRequests, message: "Rate limit exceeded").toNSError()
		case 500, 502, 503, 523:
			return Error(code: .Unauthorized, message: "Server error").toNSError()
		default:
			return Error(code: .UnexpectedHTTPStatusCode, message: "Expecting \(statusCodes), got \(response.statusCode)").toNSError()
		}
	}

	private func dataToLights(data: NSData?) -> (lights: [Light], error: NSError?) {
		guard let data = data else {
			return ([], Error(code: .JSONInvalid, message: "No data").toNSError())
		}

		let rootJSONObject: AnyObject?
		do {
			rootJSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
		} catch let error as NSError {
			return ([], error)
		}

		let lightJSONObjects: [NSDictionary]
		if let array = rootJSONObject as? [NSDictionary] {
			lightJSONObjects = array
		} else {
			lightJSONObjects = []
		}

		var lights: [Light] = []
		for lightJSONObject in lightJSONObjects {
			if let id = lightJSONObject["id"] as? String,
				power = lightJSONObject["power"] as? String,
				brightness = lightJSONObject["brightness"] as? Double,
				colorJSONObject = lightJSONObject["color"] as? NSDictionary,
				colorHue = colorJSONObject["hue"] as? Double,
				colorSaturation = colorJSONObject["saturation"] as? Double,
				colorKelvin = colorJSONObject["kelvin"] as? Int,
				label = lightJSONObject["label"] as? String,
				connected = lightJSONObject["connected"] as? Bool {
					let group: Group?
					if let groupJSONObject = lightJSONObject["group"] as? NSDictionary,
						groupId = groupJSONObject["id"] as? String,
						groupName = groupJSONObject["name"] as? String {
							group = Group(id: groupId, name: groupName)
					} else {
						group = nil
					}

					let location: Location?
					if let locationJSONObject = lightJSONObject["location"] as? NSDictionary,
						locationId = locationJSONObject["id"] as? String,
						locationName = locationJSONObject["name"] as? String {
							location = Location(id: locationId, name: locationName)
					} else {
						location = nil
					}

					let color = Color(hue: colorHue, saturation: colorSaturation, kelvin: colorKelvin)
                    let light = Light(id: id, power: power == "on", brightness: brightness, color: color, label: label, connected: connected, group: group, location: location, touchedAt: NSDate())
					lights.append(light)
			} else {
				return ([], Error(code: .JSONInvalid, message: "JSON object is missing required properties").toNSError())
			}
		}
		return (lights, nil)
	}

	private func dataToScenes(data: NSData?) -> (scenes: [Scene], error: NSError?) {
		guard let data = data else {
			return ([], Error(code: .JSONInvalid, message: "No data").toNSError())
		}

		let rootJSONObject: AnyObject?
		do {
			rootJSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
		} catch let error as NSError {
			return ([], error)
		}

		let sceneJSONObjects: [NSDictionary]
		if let array = rootJSONObject as? [NSDictionary] {
			sceneJSONObjects = array
		} else {
			sceneJSONObjects = []
		}

		var scenes: [Scene] = []
		for sceneJSONObject in sceneJSONObjects {
			if let uuid = sceneJSONObject["uuid"] as? String,
				name = sceneJSONObject["name"] as? String,
				stateJSONObjects = sceneJSONObject["states"] as? [NSDictionary] {
				var states: [State] = []
				for stateJSONObject in stateJSONObjects {
					if let rawSelector = stateJSONObject["selector"] as? String,
						selector = LightTargetSelector(stringValue: rawSelector) {
							let brightness = stateJSONObject["brightness"] as? Double ?? nil
							let color: Color?
							if let colorJSONObject = stateJSONObject["color"] as? NSDictionary,
								colorHue = colorJSONObject["hue"] as? Double,
								colorSaturation = colorJSONObject["saturation"] as? Double,
								colorKelvin = colorJSONObject["kelvin"] as? Int {
									color = Color(hue: colorHue, saturation: colorSaturation, kelvin: colorKelvin)
							} else {
								color = nil
							}
							let power: Bool?
							if let powerJSONValue = stateJSONObject["power"] as? String {
								power = powerJSONValue == "on"
							} else {
								power = nil
							}
							let state = State(selector: selector, brightness: brightness, color: color, power: power)
							states.append(state)
					}
				}
				let scene = Scene(uuid: uuid, name: name, states: states)
				scenes.append(scene)
			}
		}
		return (scenes, nil)
	}

	private func dataToResults(data: NSData?) -> (results: [Result], error: NSError?) {
		guard let data = data else {
			return ([], Error(code: .JSONInvalid, message: "No data").toNSError())
		}

		let rootJSONObject: AnyObject
		do {
			rootJSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
		} catch let error as NSError {
			return ([], error)
		}

		let resultJSONObjects: [NSDictionary]
		if let dictionary = rootJSONObject as? NSDictionary, array = dictionary["results"] as? [NSDictionary] {
			resultJSONObjects = array
		} else {
			resultJSONObjects = []
		}

		var results: [Result] = []
		for resultJSONObject in resultJSONObjects {
			if let id = resultJSONObject["id"] as? String, status =  Result.Status(rawValue: resultJSONObject["status"] as? String ?? "unknown") {
				let result = Result(id: id, status: status)
				results.append(result)
			} else {
				return ([], Error(code: .JSONInvalid, message: "JSON object is missing required properties").toNSError())
			}
		}

		return (results, nil)
	}
}
