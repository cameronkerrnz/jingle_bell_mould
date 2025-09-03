$fn = 32;

ball_diameter = 55;
locator_pin_diameter = 12;
locator_pins_offset_from_center = ball_diameter / 2 + locator_pin_diameter;
locator_pins_offset_xy = locator_pins_offset_from_center * 1/sqrt(2);

module ball_angel() {
    $fn=128;
    
    detail_raised = 2;
    
    difference() {
        union() {
            for(r = [0 : 90 : 359]) {
                rotate([90,0,r+45])
                translate([0,5,0])
                linear_extrude(h=ball_diameter, scale=2.0, convexity=4) {
                    scale(0.1) translate([-85,-160,0])
                        import("angel_mould.svg");
                }
            }
            sphere(d=ball_diameter);
        }
        difference() {
            cube([ball_diameter*2,ball_diameter*2,ball_diameter*2], center = true);
            sphere(r=ball_diameter/2 + detail_raised);
        }
    }
}

module ball_koru_stars() {
    $fn=64;
    
    detail_raised = 2;
    detail_sunken = 2;
    
    difference() {
        union() {
            for(r = [0 : 90 : 359]) {
                rotate([90,0,r+45])
                translate([0,5,0])
                linear_extrude(h=ball_diameter, scale=2, convexity=6) {
                    scale(0.15) translate([-120,-160,0]) 
                        import("koru_stars.svg", layer="Raised", $fn=4);
                }
            }
            sphere(d=ball_diameter);
        }
        difference() {
            cube([ball_diameter*2,ball_diameter*2,ball_diameter*2], center = true);
            sphere(r=ball_diameter/2 + detail_raised);
        }
                    
        intersection() {
            difference() {
                for(r = [0 : 90 : 359]) {
                    rotate([90,0,r+45])
                        translate([0,5,0])
                        linear_extrude(h=ball_diameter, scale=2, convexity=6) {
                        scale(0.15) translate([-120,-160,0]) 
                            import("koru_stars.svg", layer="Sunken", $fn=4);
                    }
                }
                sphere(r=ball_diameter/2 - detail_sunken); // inner surface of stars
            }
            sphere(d=ball_diameter+1); // outer surface of stars
        }

    }
}

module ball_press() {
    wall_thickness = 3;
    outer_radius = ball_diameter / 2;
    inner_radius = outer_radius - wall_thickness;
    rise_above = 4;
    locator_pin_taper_start_below = 3 + ball_diameter * 0.05;
    locator_pin_taper_length = ball_diameter * 0.2;
    arm_thickness = locator_pin_diameter;
    
    difference() {
        union() {
            sphere(r=outer_radius);
            rotate([90,0,0]) cylinder(r=outer_radius, h=rise_above);
        }
        translate([0,-100/2-rise_above,0]) cube([300,100,300],center=true);
        union() {
            sphere(r=inner_radius);
            rotate([90,0,0]) cylinder(r=inner_radius, h=inner_radius);
        }
    }
    rotate([0,45,0]) translate([0,-rise_above/2,0]) cube([locator_pins_offset_from_center*2, rise_above, arm_thickness], center=true);
    rotate([0,90+45,0]) translate([0,-rise_above/2,0]) cube([locator_pins_offset_from_center*2, rise_above, arm_thickness], center=true);
    for(r = [0 : 90 : 359]) {
        rotate([0,45+r,0]) 
          translate([-locator_pins_offset_from_center,-rise_above,0])
          rotate([-90,0,0]) {
            cylinder(h=rise_above + locator_pin_taper_start_below,d=locator_pin_diameter);
            translate([0,0,rise_above + locator_pin_taper_start_below])
                cylinder(h=locator_pin_taper_length, d1=locator_pin_diameter, d2=locator_pin_diameter * 0.5);
        }
    }
}

module ball_mould_blank() {
    shell_thickness = 3;
    mould_width = ball_diameter + 2 * shell_thickness;
    rib_count = 3; // must be odd
    mid_rib = ceil(rib_count / 2); // 1 based
    rib_thickness = 3;
    rib_bc = mould_width / (rib_count + 1);
    flange_radius = shell_thickness; // rough
    
    difference() {
        union() {
            sphere(d=ball_diameter + 2*shell_thickness, $fn=32);
            for(rib = [1 : rib_count]) {
                translate([rib * rib_bc - mould_width / 2, 0, 0])
                    cube([((rib == mid_rib) ? 2 : 1) * rib_thickness, mould_width, mould_width], center=true);
            }
            for(rib = [1 : rib_count]) {
                translate([0, 0, rib * rib_bc - mould_width / 2])
                    cube([mould_width, mould_width, rib_thickness], center=true);
            }
            // break-line with additional flange for locator pins
            difference() {
                translate([0, rib_thickness/2, 0])
                    cube([mould_width, rib_thickness, mould_width], center=true);
                for(r = [0 : 90 : 359]) {
                    rotate([0,r,0])
                        hull() {
                            translate([-mould_width/2+flange_radius,0,mould_width/2-flange_radius])
                                rotate([-90,0,0]) 
                                cylinder(r=flange_radius, h=rib_thickness);
                            translate([-mould_width/2,0,mould_width/2])
                                rotate([-90,0,0]) 
                                cylinder(r=flange_radius*2, h=rib_thickness);
                        }
                }
            }
        }
        // front-plane (break-line for mould)
        translate([0,-500,0]) cube(1000,center=true);
        // print-bed, to ensure part of shell is on the print-bed
        translate([0,500+mould_width/2 - shell_thickness*0.5,0]) cube(1000,center=true);
        // round the corners of the flange
        
    }
}

module ball_mould() {
    difference() {
        ball_mould_blank();
        children();
    }
}

module quarter_mould_left() {
    intersection() {
        ball_mould() { children(); }
        translate([-1000,0,0]) cube([2000,2000,2000],center=true);
    }
}

module quarter_mould_right() {
    intersection() {
        ball_mould() { children(); }
        translate([1000,0,0]) cube([2000,2000,2000],center=true);
    }
}


module print_set() {
    // for 55mm ball_diameter at the moment (heights need adjusting)
    translate([ball_diameter,0,4]) rotate([90,0,0]) ball_press();
    translate([-0.6 * ball_diameter,0,29]) rotate([-90,0,0]) quarter_mould_left() children();
    translate([-0.4 * ball_diameter,0,29]) rotate([-90,0,0]) quarter_mould_right() children();
}

//print_set() ball_koru_stars();
print_set() ball_angel();

