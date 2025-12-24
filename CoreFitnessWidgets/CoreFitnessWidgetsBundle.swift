//
//  CoreFitnessWidgetsBundle.swift
//  CoreFitnessWidgets
//
//  Created by Jeff Miller on 12/23/25.
//

import WidgetKit
import SwiftUI

@main
struct CoreFitnessWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CoreFitnessWidgets()
        CoreFitnessWidgetsControl()
        WorkoutLiveActivity()
    }
}
