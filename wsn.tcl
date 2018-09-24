# ======================================================================
# Define options
# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy/802_15_4
set val(mac)            Mac/802_15_4
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         150                         ;# max packet in ifq
set val(nn)             4                         ;# number of mobilenodes
set val(rp)             AODV                       ;# routing protocol
set val(x)  50
set val(y)  50
#Queue/DropTail/PriQueue set Prefer_Routing_Protocols    1
#LL set mindelay_                50us
#LL set delay_                   25us
#LL set bandwidth_               0       ;# not used
#LL set-limit 1000000




# ================================= 
# Antenna Settings 
# ================================= 
Antenna/OmniAntenna set X_ 0 
Antenna/OmniAntenna set Y_ 0 
Antenna/OmniAntenna set Z_ 1.5 
Antenna/OmniAntenna set Gt_ 1.0  
Antenna/OmniAntenna set Gr_ 1.0 
#======================
#Physica layer setting 
#======================
Phy/WirelessPhy set freq_ 2.4e+9 ;# The working band is 2.4GHz 
Phy/WirelessPhy set L_ 0.5   ;#Define teh system loss in TwoRayGround 
Phy/WirelessPhy set  bandwidth_  28.8*10e3   ;#28.8 kbps 
# For model 'TwoRayGround'
# The received signals strengths  in different distances 
set dist(5m)  7.69113e-06
set dist(9m)  2.37381e-06
set dist(10m) 1.92278e-06
set dist(11m) 1.58908e-06
set dist(12m) 1.33527e-06
set dist(13m) 1.13774e-06
set dist(14m) 9.81011e-07
set dist(15m) 8.54570e-07
set dist(16m) 7.51087e-07
set dist(20m) 4.80696e-07
set dist(25m) 3.07645e-07
set dist(30m) 2.13643e-07
set dist(35m) 1.56962e-07
set dist(40m) 1.20174e-07
Phy/WirelessPhy set CSThresh_  ;#$dist(40m)
Phy/WirelessPhy set RXThresh_  ;#$dist(40m)
#Phy/WirelessPhy set CPThresh_ 10 
# According to the Two-Ray Ground propagation model 
#Pr(d) = Pt*Gt*Gr*ht*ht*hr*hr/(d*d*d*d*L)
# thus the transmitted signal power
#average Pt= d*d*d*d*L*Pr(d)/(Gt*Gr*ht*ht*hr*hr) = 1mW     
Phy/WirelessPhy set  pt_ 0.001
#Specified Parameters for 802.15.4 MAC
Mac/802_15_4 wpanCmd verbose on   ;# to work in verbose mode 
Mac/802_15_4 wpanNam namStatus on  ;# default = off (should be turned on before other 'wpanNam' commands can work)

# Initialize Global Variables
set ns_  [new Simulator]

$ns_ color 1 Blue
$ns_ color 2 Red
$ns_ color 3 Green

# Tell teh simulator to use teh new type trace data 
$ns_ use-newtrace
set scenario1   [open scenario1.tr w]
$ns_ trace-all $scenario1
#Define the NAM output file
set scenario1nam     [open scenario1.nam w]
$ns_ namtrace-all-wireless $scenario1nam $val(x) $val(y)
$ns_ puts-nam-traceall {# nam4wpan #}  ;# inform nam that this is a trace file for wpan (special handling needed)

# set up topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Create God 
set god_ [create-god $val(nn)]
set chan_1_ [new $val(chan)]

# configure node
$ns_ node-config -adhocRouting $val(rp) \
  -llType $val(ll) \
  -macType $val(mac) \
  -ifqType $val(ifq) \
  -ifqLen $val(ifqlen) \
  -antType $val(ant) \
  -propType $val(prop) \
  -phyType $val(netif) \
  -topoInstance $topo \
  -agentTrace OFF \
  -routerTrace OFF \
  -macTrace ON \
  #-movementTrace OFF \
                -energyModel "EnergyModel"\
                -initialEnergy 100\
                -rxPower 0.3\
                -txPower 0.3\
  -channel $chan_1_ 

for {set i 0} {$i < $val(nn) } {incr i} {
 set node_($i) [$ns_ node] 
 $node_($i) random-motion 0  ;# disable random motion
 $god_ new_node $node_($i)
}
#Lable the sink node 
$ns_ at 0.0 "$node_(3) NodeLabel Sink"
# Define the nodes positions 
$node_(0) set X_ 15.0
$node_(0) set Y_ 20.0
$node_(0) set Z_ 0.000000000000
$node_(1) set X_ 25.0
$node_(1) set Y_ 20.0
$node_(1) set Z_ 0.000000000000
$node_(2) set X_ 35.0
$node_(2) set Y_ 20.0
$node_(2) set Z_ 0.000000000000
$node_(3) set X_ 5.0
$node_(3) set Y_ 5.0
$node_(3) set Z_ 0.000000000000

set null [new Agent/Null]
$ns_ attach-agent $node_(3) $null
# Define the cbr traffic 

set udp0 [new Agent/UDP]
$ns_ attach-agent $node_(0) $udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.02
$cbr0 attach-agent $udp0
$udp0 set class_ 1
$ns_ connect $udp0 $null  
$ns_ at 0.1 "$cbr0 start"
$ns_ at 0.9 "$cbr0 stop"

set udp1 [new Agent/UDP]
$ns_ attach-agent $node_(1) $udp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 800
#$cbr1 set rate_ 600Kb
$cbr1 set interval_ 0.02
$cbr1 attach-agent $udp1
$udp1 set class_ 2
$ns_ connect $udp1 $null 
$ns_ at 0.2 "$cbr1 start"
$ns_ at 0.8 "$cbr1 stop"

set udp2 [new Agent/UDP]
$ns_ attach-agent $node_(2) $udp2
set cbr2 [new Application/Traffic/CBR]
$cbr2 set packetSize_ 100
$cbr2 set interval_ 0.02
$cbr2 attach-agent $udp2
$udp2 set class_ 3
$ns_ connect $udp2 $null  
$ns_ at 0.3 "$cbr2 start"
$ns_ at 0.7 "$cbr2 stop"

# defines the node size in nam
for {set i 0} {$i < $val(nn)} {incr i} {
 $ns_ initial_node_pos $node_($i) 5
}

# Tell nodes simulation ends at 10.0
for {set i 0} {$i < $val(nn) } {incr i} {
   $ns_ at 1.0 "$node_($i) reset";
}
$ns_ at 1.0 "stop"
$ns_ at 1.0 "puts \"\nNS EXITING...\""
$ns_ at 1.0 "$ns_ halt"

proc stop {} {
    global ns_ scenario1 scenario1nam
    $ns_ flush-trace
    close $scenario1
    #set hasDISPLAY 0
    exec nam scenario1.nam &
 
}
puts "\nStarting Simulation..."
$ns_ run