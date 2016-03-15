## DOUGLAS DC-9-32 SYSTEMS FILE
###############################

## LIVERY SELECT
################

aircraft.livery.init("Aircraft/DC-9-32/Models/Liveries");

## ALS LANDING LIGHTS
##########

setprop("/sim/rendering/als-secondary-lights/use-landing-light", 1);
setprop("/sim/rendering/als-secondary-lights/use-alt-landing-light", 1);

## ENGINES
##########

# explanation of engine properties
# controls/engines/engine[X]/throttle-lever	When the engine isn't running, this value is constantly set to 0; otherwise, we transfer the value of controls/engines/engine[X]/throttle to it
# controls/engines/engine[X]/starter		Triggering it fires up the engine
# engines/engine[X]/running			Set based on the engine state
# engines/engine[X]/rpm				Used in place of the n1 value for the animations and set dynamically based on the engine state
# engines/engine[X]/failed			When triggered the engine is "failed" and cannot be restarted
# engines/engine[X]/on-fire			Self-explanatory

# engine loop function
var engineLoop = func(engine_no)
 {
 # control the throttles and main engine properties
 var engineCtlTree = "controls/engines/engine[" ~ engine_no ~ "]/";
 var engineOutTree = "engines/engine[" ~ engine_no ~ "]/";

 # the FDM switches the running property to true automatically if the cutoff is set to false, this is unwanted
 if (props.globals.getNode(engineOutTree ~ "running").getBoolValue() and !props.globals.getNode(engineOutTree ~ "started").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  }

 if (props.globals.getNode(engineOutTree ~ "on-fire").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "failed").setBoolValue(1);
  }
 if (props.globals.getNode(engineCtlTree ~ "cutoff").getBoolValue() or props.globals.getNode(engineOutTree ~ "failed").getBoolValue() or props.globals.getNode(engineOutTree ~ "out-of-fuel").getBoolValue())
  {
  if (getprop(engineOutTree ~ "rpm") > 0)
   {
   var rpm = getprop(engineOutTree ~ "rpm");
   rpm -= getprop("sim/time/delta-realtime-sec") * 2.5;
   setprop(engineOutTree ~ "rpm", rpm);
   }
  else
   {
   setprop(engineOutTree ~ "rpm", 0);
   }

  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  props.globals.getNode(engineOutTree ~ "started").setBoolValue(0);
  setprop(engineCtlTree ~ "throttle-lever", 0);
  }
 elsif (props.globals.getNode(engineCtlTree ~ "starter").getBoolValue() and props.globals.getNode("systems/electrical/APU/running").getBoolValue())
  {
  props.globals.getNode(engineCtlTree ~ "cutoff").setBoolValue(0);

  var rpm = getprop(engineOutTree ~ "rpm");
  rpm += getprop("sim/time/delta-realtime-sec") * 3.0;
  setprop(engineOutTree ~ "rpm", rpm);

  if (rpm >= getprop(engineOutTree ~ "n1"))
   {
   props.globals.getNode(engineCtlTree ~ "starter").setBoolValue(0);
   props.globals.getNode(engineOutTree ~ "started").setBoolValue(1);
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(1);
   }
  else
   {
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
   }
  }
 elsif (props.globals.getNode(engineOutTree ~ "running").getBoolValue())
  {
  if (getprop("autopilot/settings/speed") == "speed-to-ga")
   {
   setprop(engineCtlTree ~ "throttle-lever", 1);
   }
  else
   {
   setprop(engineCtlTree ~ "throttle-lever", getprop(engineCtlTree ~ "throttle"));
   }

  setprop(engineOutTree ~ "rpm", getprop(engineOutTree ~ "n1"));
  }

 settimer(func
  {
  engineLoop(engine_no);
  }, 0);
 };
# APU loop function
var apuLoop = func()
 {
 var apuOutTree = "engines/apu/";

 if (props.globals.getNode("controls/electric/APU-generator").getBoolValue() and props.globals.getNode("controls/APU/fuel-pump").getBoolValue())
  {
  var rpm = getprop(apuOutTree ~ "rpm");
  rpm += getprop("sim/time/delta-realtime-sec") * 15;
  if (rpm > 99)
   {
   props.globals.getNode(apuOutTree ~ "running").setBoolValue(1);
   }
  if (rpm > 100)
   {
   rpm = 100;
   }
  setprop(apuOutTree ~ "rpm", rpm);
  }
 else
  {
  props.globals.getNode(apuOutTree ~ "running").setBoolValue(0);

  var rpm = getprop(apuOutTree ~ "rpm");
  rpm -= getprop("sim/time/delta-realtime-sec") * 20;
  if (rpm < 0)
   {
   rpm = 0;
   }
  setprop(apuOutTree ~ "rpm", rpm);
  }

 settimer(func
  {
  apuLoop();
  }, 0);
 };
# start the loops 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  engineLoop(0);
  engineLoop(1);
  apuLoop();
  }, 2);
 });

# startup/shutdown functions
var startup = func
 {
 setprop("controls/engines/engine[0]/cutoff", 0);
 setprop("controls/engines/engine[1]/cutoff", 0);
 setprop("engines/engine[0]/started", 1);
 setprop("engines/engine[1]/started", 1);
 setprop("controls/electric/battery-switch", 1);
 };
var shutdown = func
 {
 setprop("controls/engines/engine[0]/cutoff", 1);
 setprop("controls/engines/engine[1]/cutoff", 1);
 setprop("engines/engine[0]/started", 0);
 setprop("engines/engine[1]/started", 0);
 setprop("controls/electric/battery-switch", 0);
 };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
  props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
  }
 });

