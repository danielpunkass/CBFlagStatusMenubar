//
//  AppDelegate.swift
//  CBoatingMenuBar
//
//  Created by Peter  Blanco on 5/31/16.
//  Copyright © 2016 Peter  Blanco. All rights reserved.
//

import Cocoa

enum FlagStatus : String {
	case closed = "C"
    case green = "G"
	case yellow = "Y"
	case red = "R"
}

extension NSColor.Name {
	static let greenFlag = "GreenFlag"
	static let yellowFlag = "YellowFlag"
	static let redFlag = "RedFlag"
	static let closedFlag = "ClosedFlag"
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    
	let statusItem = NSStatusBar.system.statusItem(withLength: -1)
	var flagColor: NSColor = .black {
		didSet {
			self.statusItem.image = NSImage(size: NSSize(width: 20, height: 16), flipped: false, drawingHandler: { rect in
				let flagPath = NSBezierPath()

				let insetAmount = 2.0
				let targetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
				let bottomLeftPoint = CGPoint(x: targetRect.minX, y: targetRect.minY)
				let topLeftPoint = CGPoint(x: targetRect.minX, y: targetRect.maxY)
				let middleRightPoint = CGPoint(x: targetRect.maxX, y: targetRect.midY)

				flagPath.move(to: bottomLeftPoint)
				flagPath.line(to: topLeftPoint)
				flagPath.line(to: middleRightPoint)
				flagPath.close()

				self.flagColor.setFill()
				flagPath.fill()

				NSColor.labelColor.setStroke()
				flagPath.lineWidth = 1.0
				flagPath.stroke()

				return true
			})
		}
	}
	var flagStatus = FlagStatus.closed {
		didSet {
			switch self.flagStatus {
				case .closed: self.flagColor = NSColor(named: .closedFlag)!
				case .green: self.flagColor = NSColor(named: .greenFlag)!
				case .yellow: self.flagColor = NSColor(named: .yellowFlag)!
				case .red: self.flagColor = NSColor(named: .redFlag)!
			}
		}
	}

#if DEBUG
	@objc func simulateStatus(_ sender: NSMenuItem) {
		if let statusString = sender.representedObject as? String, let status = FlagStatus(rawValue: statusString) {
			self.flagStatus = status
		}
	}
#endif

	func applicationDidFinishLaunching(_ aNotification: Notification) {
#if DEBUG
		self.statusMenu.items.append(NSMenuItem.separator())
		for flagStatus in ["R", "G", "Y", "C"] {
			self.statusMenu.addItem(withTitle: "Simulate \(flagStatus) Status", action: #selector(simulateStatus(_:)), keyEquivalent: "")
			self.statusMenu.items.last?.representedObject = flagStatus
		}
#endif

		self.statusItem.menu = self.statusMenu;

		updateFlag();
		Timer.scheduledTimer(timeInterval: 360, target: self, selector: #selector(AppDelegate.updateFlag), userInfo: nil, repeats: true);
    }
    
	@objc func updateFlag() -> Void {
		if let url = URL(string: "https://api.community-boating.org/api/flag") {
			let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
				if let data = data,
				   let dataString = String(data: data, encoding: .utf8)
				{
					let splitString = dataString.components(separatedBy: "\"")
					if splitString.count > 1 {
						let statusString = splitString[1]
						if let status = FlagStatus(rawValue: statusString) {
							DispatchQueue.main.async {
								self.flagStatus = status
							}
						}
					}
				}
			}

			task.resume()
		}
    }

    @IBAction func openWeatherPage(_ sender: NSMenuItem) {
        let url = URL(string: "https://www.community-boating.org/about-us/weather-information/");
		NSWorkspace.shared.open(url!)
    }
    
}

