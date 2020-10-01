// Elixer Space Company - Main Script [version 0.8] 

// TODO LIST:
// 
// Bind action group 7 to cut drogues and deploy mains

// BUG LIST:
// 
// 
// 
// 
//

// Mission Parameters


set targetOrbit to 100000. 
set targetInclination to 0.

set targetPlanet to kerbin.

set count to 10.

set HopperAp to 10000.

set HopAP to 80000.
set E_To_E_landing_position to 1. // [1 = 34,70] [2 = 45,120]

set staticFireGimbalTest to 1. // 1 = True | 0 = False
set staticFireLength to 100. // Must be above 15 Unless Gimal Test is set to False.

set horizontalAltitude to 70000.


// Type Of Mission


set missionType to 1. // [1 = Cargo] [2 = Crewed] [3 = Hop] [4 = Static Fire] [5 = Interplanetary] [6 = Short Hops]
set landingType to 2. // [1 = RTLS] [2 = ASDS] [3 = AOTL] [4 = E-EHL]


// Throttle setup


set throt to 0.
lock throttle to throt.


// Initialisation


wait until ag6.
parameterChecks().


// Mission Safety Checks


function parameterChecks {
    // User Input Checks

    if (targetOrbit < 70000) {
        print "Target Orbit too low: " + targetOrbit.
        abort on.
        shutdown.
    } else {
        print "Target Orbit set: " + targetOrbit.
    }

    if (targetInclination > 90) {
        print "Inclination too high: " + targetInclination.
        abort on.
        shutdown.
    } else if (targetInclination < -90) {
        print "Inclination too low: " + targetInclination.
        abort on.
        shutdown.
    } else {
        print "Target Inclination set: " + targetInclination.
    }

    // Mission Type Checks

    if (missionType = 1) {
        set hasFairings to true.
        set hasCargo to true.
        //set hasCrew to false. 
        set canAbort to false. //abort check
        set flightDone to false.
        CargoSequence().
    } else if (missionType = 2) {
        set hasFairings to false.
        set hasCargo to false.
        //set hasCrew to true.
        set canAbort to true.
        set flightDone to false.
        CrewSequence().
    } else if (missionType = 3) {
        set hasFairings to false.
        set hasCargo to false.
        //set hasCrew to true.
        set canAbort to true.
        set flightDone to false.
        HopSequence().
    } else if (missionType = 4) {
        StaticFire().
    } else if (missionType = 5) {
        set canAbort to true.
        Interplanetary().
    } else if (missionType = 6) {
        set canabort to true.
        Hopper().
    }

    // Landing Type Checks

    if (landingType = 1) {
        //latlng
    } else if (landingType = 2) {
        //latlng
    } else if (landingType = 3) {
       //latlng
    } else if (landingType = 4) {
        //latlng
    }

    // Earth - Earth LZ

    if (E_To_E_landing_position = 1) {
        parameter E_To_E_landing_position is Latlng(34, 70).
    } 
    else if (E_To_E_landing_position = 2) {
        parameter E_To_E_landing_position is latlng(45, 120).
    }

}

function abortSequence { 
    set throt to 0.
    wait 1.
    abort on.
    lock steering to heading(0, 45, 180).
    set throt to 1. 
    wait until ship:availableThrust < 1. 
    set throt to 0.
    when (altitude < 5000) then {
        ag7 on.
    }
}

function abortSuborbital {
    stage. //seperating the spacecraft from launch vehicle
    lock steering to heading(0, 0, 180).
    //wait until stage:ready.
    stage. //seperating trunk
    lock steering to retrograde.
    when alt:radar < 5000 then {
        ag7 on.
    } 
}


// Cargo Flight 


function CargoSequence {
    set TOIBlock to true.
    Cargo1(). // Liftoff
    Cargo2(). // Ascent
    Cargo3(). // Main Engine Cut off
    Cargo4(). // Second Stage
    wait until TOIBlock = false.
    Cargo5(). // Second Stage Guidance
    Cargo6(). // Orbital Insertion Burn
    wait until flightDone = true.
    Cargo10(). // Payload Deployment
}

function Cargo1 {
    until count = 0 {
        set count to count - 1.
        print "T-" + count.
        wait 1.
        clearscreen.
    }
    clearscreen.

    set throt to 1.
    stage. // Point of liftoff
}

function Cargo2 {
    lock steering to heading(90-targetInclination, 90-90*(apoapsis/horizontalAltitude)).
    
    when (apoapsis >= horizontalAltitude) then {
        lock steering to heading(90-targetInclination, 0.5).
    }
}

function Cargo3 {
    when (ship:liquidfuel < 23000) then {
        set throt to 0.1.
        wait .8.
        set throt to 0.
        wait 1.
        toggle ag8.
        stage.
        rcs on.
        wait 2.25.
        set throt to 1.
    }
}

function Cargo4 {
    when altitude > 60000 and hasFairings = true then {
        stage.
    }

    when apoapsis > targetOrbit then {
        set throt to 0.
        set TOIBlock to false.
    }
}

function Cargo5 {
    set targetVel to sqrt(ship:body:mu/(ship:orbit:body:radius + ship:orbit:apoapsis)).
	set apVel to sqrt(((1 - ship:orbit:ECCENTRICITY) * ship:orbit:body:mu) / ((1 + ship:orbit:ECCENTRICITY) * ship:orbit:SEMIMAJORAXIS)).
    set dv to targetVel - apVel.
    set mynode to node(time:seconds + eta:apoapsis, 0, 0, dv).
	add mynode.
    
    lock steering to lookdirup(ship:prograde:vector, heading(180, 0):vector).
}

function Cargo6 {
    set nd to nextnode.
	set max_acc to ship:maxthrust / ship:mass.
	set burn_duration to nd:deltav:mag/max_acc.
    wait until nd:eta <= (burn_duration/2 + 60).
	
	set np to nd:deltav.
	lock steering to np.
	wait until vang(np, ship:facing:vector) < 0.33.
	
	wait until nd:eta <= (burn_duration/2).

	set dv0 to nd:deltav.
	set done to false.

	until done {
		wait 0.
		set max_acc to ship:maxthrust / ship:mass.

		set throt to min(nd:deltav:mag/max_acc, 1).
		
		if vdot(dv0, nd:deltav) < 0 {
			set throt to 0.
			break.
		}
		
		if nd:deltav:mag < 0.1 {
            wait until vdot(dv0, nd:deltav) < 0.5.
			set throt to 0.
            set flightDone to true.
			set done to true.
        }

	}
}

function Cargo10 {
    clearscreen.
    print "starting cargo 10".

    print "Payload Deployment in 15 seconds".
    wait 15.

    stage.
    wait 5.
    //stage.
    // Use as many as we need for mission.

}


// Crew Flight


function CrewSequence {
    Crew1(). // Liftoff
    Crew2(). // Ascent
    Crew3(). // Main Engine Cut off
    Crew4(). // Second Stage
    Crew5(). // Second Engine Cut off
    Crew6(). // Orbital Insertion Burn
    Crew7(). // Extra 1
    Crew8(). // Extra 2
    Crew9(). // Extra 3
    Crew10(). // Capsule Deployment
}

function Crew1 { //should i leave this commented out or no?
  //  set maxThrustStart to ship:maxthrust.
  //  set launchPhaseD to 1. 
  //  set launchPartsD to ship:parts. 
  //  set stagedD to false.
  //  until launchPhaseD = 2 {
   // if canAbort = true {
  //      if ship:maxThrust < maxThrustStart * 0.8 {
   //         abortSequence().
  //      }
   //     else if launchPartsD > ship:parts {
  //          abortSequence().       
  //      }
  //  } 
  //  when altitude > 1000 then {
  //     set launchPhaseD to 2.
 //       break.
  //  }
  //  }
}

function Crew2 {
    
  // if launchPartsD > ship:parts { //if part count is reduced ,abort
 //      abortSequence().
  // }
}

function Crew3 {
   // wait 6.
   // set stagedD to true.
    //if launchPartsD = ship:parts { //this is subject to change, this is supposed to wait for the staging to happen
    //    abortSequence(). // and if the part count doesn't go down it aborts
   // }
}

function Crew4 {
  set canAbort to false.
  set canAbortOBT to true.
  set canAbortShutdown to true.
}

function Crew5 {
    // if apoapsis < 70000 { 
    // abortSuborbital().
    // }
    // else if (apoap{
    //     print "No Abort Needed".
    // }
}

function Crew6 {
    //are you shure about that

}

function Crew7 {
    //
}

function Crew8 {
    //
}

function Crew9 {
    //
}

function Crew10 {
    //
}


// Hop

function Target_lz {
    return E_To_E_landing_position.
}

function HopSequence {
    
    HS1(). //iginition/ liftoff
    HS2(). // gravity turn
    HS3(). //landing alignment
    HS4(). // coast phase
    HS5(). // reentry
    HS6(). //switching to landing
}

function HS1 {

    until count = 0 {
        set count to count - 1.
        print "T-" + count.
        wait 1.
        clearscreen.
    }
    clearscreen.
    print "Committed".

    set throt to 1.
    lock steering to up.
    stage. //ignition
    wait 1.
    stage.  //point of liftoff
    print "starting HS2".
    wait 8.
}

function HS2 {
    clearScreen.
    set horizontalAltitude to 80000.
    set throt to 1.
    lock steering to heading(90 - targetInclination, 90-90 * (apoapsis/horizontalAltitude)). 

    when altitude > horizontalAltitude then {
        lock steering to heading(90 - targetInclination, 0.5).
    }

    if ship:apoapsis > 79900 {
        set throt to 0.
        print "apoapsis reached".
        wait 3.
        clearscreen.
        print "tarting HS3".
    }
    else HS2(). //loops until true

}

function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
        return ship:geoposition.
}

function lngError {
    return getImpact():lng - E_To_E_landing_position:lng.
}

function latError {
    return getImpact():lat - E_To_E_landing_position:lat.
}

function HS3 {
    clearScreen.
    if latError() <> E_To_E_landing_position{
        if latError():lat < E_To_E_landing_position:lat {
            lock steering to heading(90,0).
            set throt to 1.
            if lngError():lat >= E_To_E_landing_position:lat  {
                set throt to 0.
            }
            else HS3().
        }
        if laterror():lat > E_To_E_landing_position:lat {
            lock steering to heading(-90,0).
            set throt to 1.
        
            if laterror():lat <= E_To_E_landing_position:lat {
                set throt to 0.
            }
            else HS3().
        }
        if lngerror():lng < E_To_E_landing_position:lng {
            lock steering to heading(0,0).
            set throt to 1.
            if lngerror():lng >= E_To_E_landing_position:lng {
                set throt to 0.
            }
            else HS3().
        }
        if lngerror():lng > E_To_E_landing_position:lng {
            lock steering to heading(180,0).
            set throt to 1.
            if lngerror():lng <= E_To_E_landing_position:lng {
                set throt to 0.
            }
            else HS3().
        }
    }
}

function HS4 { //coast phase
    print "entering coast phase".
    wait until ship:altitude = ship:apoapsis. 
    print "Reentry started".
}

function HS5 {
    if latError() <> E_To_E_landing_position{
        if latError():lat < E_To_E_landing_position:lat {
            lock steering to heading(90,0).
            set throt to 1.
            if lngError():lat >= E_To_E_landing_position:lat  {
                set throt to 0.
            }
            else HS5().
        }
        if laterror():lat > E_To_E_landing_position:lat {
            lock steering to heading(-90,0).
            set throt to 1.
        
            if laterror():lat <= E_To_E_landing_position:lat {
                set throt to 0.
            }
            else HS5().
        }
        if lngerror():lng < E_To_E_landing_position:lng {
            lock steering to heading(0,0).
            set throt to 1.
            if lngerror():lng >= E_To_E_landing_position:lng {
                set throt to 0.
            }
            else HS5().
        }
        if lngerror():lng > E_To_E_landing_position:lng {
            lock steering to heading(180,0).
            set throt to 1.
            if lngerror():lng <= E_To_E_landing_position:lng {
                set throt to 0.
            }
            else HS5().
        }
    }
}

function HS6 { //transfers to landing procedure
 LALZ1().
}
    

// Static Fire 


function StaticFire {
    set S1Throttleset to 0.
    if (staticFireGimbalTest = 0) {
        set staticFireLengthReq to 3.
    }
    else if (staticFireGimbalTest = 1) {
        set staticFireLengthReq to 15.
    }
    
    if staticFireLength < staticFireLengthReq {
        print "Length Too Low".
        print "Minimum Length is 15 Seconds".
        abort on.
        shutdown.
    }
    else if staticFireLength > 180 {
        print "Length Too Long".
        print "Maximum Length is 180 Seconds".
        abort on.
        shutdown.
    }
    else if staticFireLength > staticFireLengthReq { 
    // Variables
    Set S1CountdownLength to 10.
    set S1Throttleset to 2.
    S1(). // Countdown + Startup
    S2(). // Duration
    S3(). // Shutdown
    }
}

function S1 { 
    clearscreen.
    set staticfirecount to S1CountdownLength.
    until staticfirecount = 0 {
        set staticfirecount to staticfirecount - 1.
        print " T - ". 
        print staticfirecount.
        wait 1.
        clearscreen.    
    }
    wait until staticfirecount = 0.
    print "Committed".
    stage.
    wait 0.5.
    set throt to 0.5.
    wait 1.
    set throt to 1.
    wait 1.
    set S1Throttleset to 1.
    wait until S1Throttleset = 1.
    if staticFireGimbalTest = 1 {
        S2GimbalTest().
        wait 5.
        S2GimbalTest().
    }
    else if staticFireGimbalTest = 0 {
        print "No Gimbal Test".
    }
    wait staticFireLength - staticFireLengthReq.
    S3().   
}

function S3 {
    print "Shutdown".
    set throt to 0.7.
    wait 0.5.
    set throt to 0.3.
    wait 0.5.
    set throt to 0.
    print "Full Duration".
    shutdown.
}

function S2GimbalTest {
    print "Gimbal Test Started".
    lock steering to heading(90,80).
    wait 1.
    lock steering to heading(0,80).
    wait 1.
    lock steering to heading(270,80).
    wait 1.
    lock steering to heading(180,80).
    wait 1.
    lock steering to heading(90,90). 
    print "Gimbal Test Over".
}



//E-EHL landing



function LALZ1{
    LZ1_1(). // reentry burn
    LZ1_2(). //corrections/ coast
    LZ1_3(). //suicide burn
}

function LZ1_1 {
    when ship:airspeed < -1000 then {
        //set old_airspeed to ship:airspeed.
        set throt to 0.7.
        wait until ship:airspeed > -500.
        set throt to 0.
        ag9. //airbrakes (if applicible)
    }
}

function LZ1_2 {
    lock steering to srfRetrograde.
    rcs on. 
}

function LZ1_3 {
    print "beginning landing".
    lock pct to stoppingDistance() / distanceToGround().
    wait until pct > 1.
    lock steering to srfretrograde.
    lock throttle to pct.
    gear on.
    wait until ship:verticalSpeed > 0.
    lock throttle to 0.
    rcs on.
    lock steering to up.
    wait 10.
    unlock steering.
    rcs off.
} 

function stoppingDistance {
    local grav is constant():g * (body:mass / body:radius^2).
    local maxDeceleration is (ship:availableThrust / ship:mass) - grav.
    return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function distanceToGround {
    return altitude - body:geopositionOf(ship:position):terrainHeight - 6.5.
}


// Hopper


function Hopper {
    Hop1(). //ignition
    Hop2(). //burn upwards 
    Hop3(). //coast 
    Hop4().// final landing and hoverslam
}

function Hop1 {
    set runningD to true. 
    set throt to 1.
    stage.
    wait until stage:ready. 
    stage. 
    lock steering to up.
    wait 2.
}

function Hop2 {
    wait until altitude > HopperAp. 
    set throt to 0.  
    wait 2.
}

function Hop3 {
    brakes on. 
    rcs on. 
    lock steering to up.
    wait 2.
    wait until altitude < 6700.
    lock steering to (-ship:velocity:surface + up:vector).
    wait 5.
    set throt to 1.
    wait until verticalSpeed < -70. // this is the problem
    set throt to 0.
}

function Hop4 {
    set impactTime TO 4.
    SET throt TO 0.
    set radaroffset to 12.15. 
    set g to constant:g * body:mass / body:radius^2. 
    
    WAIT UNTIL ship:verticalspeed < -1.
    print "Hoverslam Setup".
    lock steering to srfretrograde.
    when impactTime < 3 then {gear on.}

    print "Hoverslam".
    until runningD = false {
        set trueRadar to alt:radar - radaroffset.
        set maxDecel to (ship:availablethrust / ship:mass) - g.
        set stopDist to ship:verticalspeed^2 / (2 * maxDecel).
        set landingThrottle to stopDist / trueRadar.
        set impactTime to trueRadar / abs(ship:verticalspeed).
    
        set throt to landingThrottle.
        if ship:verticalSpeed > -0.1 {
            set throt to 0.
            set runningD to false.
        }

        print "Hoverslam completed".
        set ship:control:pilotmainthrottle to 0.
        rcs off.
        } 
}


// Interplanetary Flight


function Interplanetary {
    I1(). // Liftoff
    I2(). // Ascent
    I3(). // Main Engine Cutoff
    I4(). // Second Stage Guidance
    wait until TOIBlock = false.
    I5(). // PreOIB
    I6(). // OIB
    I7(). // Planetary Burn
}

function I1 {
 until count = 0 {
        set count to count - 1.
        print "T-" + count.
        wait 1.
        clearscreen.
    }
    clearscreen.

    set throt to 1.
    stage. // Point of liftoff
}

function I2 {
    lock steering to heading(90-targetInclination, 90-90*(apoapsis/horizontalAltitude)).
    
    when (apoapsis >= horizontalAltitude) then {
        lock steering to heading(90-targetInclination, 0.5).
    }
}

function I3 {
    when (ship:liquidfuel < 23000) then {
        set throt to 0.1.
        wait .8.
        set throt to 0.
        wait 1.
        stage.
        rcs on.
        wait 2.25.
        set throt to 1.
    }
} 

function I4 {
    when altitude > 60000 and hasFairings = true then {
        stage.
    }

    when apoapsis > targetOrbit then {
        set throt to 0.
        set TOIBlock to false.
    }
}

function I5 {
    set targetVel to sqrt(ship:body:mu/(ship:orbit:body:radius + ship:orbit:apoapsis)).
	set apVel to sqrt(((1 - ship:orbit:ECCENTRICITY) * ship:orbit:body:mu) / ((1 + ship:orbit:ECCENTRICITY) * ship:orbit:SEMIMAJORAXIS)).
    set dv to targetVel - apVel.
    set mynode to node(time:seconds + eta:apoapsis, 0, 0, dv).
	add mynode.
    
    lock steering to lookdirup(ship:prograde:vector, heading(180, 0):vector).
}

function I6 {
    set nd to nextnode.
	set max_acc to ship:maxthrust / ship:mass.
	set burn_duration to nd:deltav:mag/max_acc.
    wait until nd:eta <= (burn_duration/2 + 60).
	
	set np to nd:deltav.
	lock steering to np.
	wait until vang(np, ship:facing:vector) < 0.33.
	
	wait until nd:eta <= (burn_duration/2).

	set dv0 to nd:deltav.
	set done to false.

	until done {
		wait 0.
		set max_acc to ship:maxthrust / ship:mass.

		set throt to min(nd:deltav:mag/max_acc, 1).
		
		if vdot(dv0, nd:deltav) < 0 {
			set throt to 0.
			break.
		}
		
		if nd:deltav:mag < 0.1 {
            wait until vdot(dv0, nd:deltav) < 0.5.
			set throt to 0.
            set flightDone to true.
			set done to true.
        }

	}
}

function I7 {
    // the hard part
}


// Put this on the 1000th line