// traffic light controller solution stretch
// CSE140L 4-street, 20-state version, ew str/left decouple
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 5 after traffic, 10 max cycles for green when other traffic present
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller2(
  input clk, reset, e_str_sensor, w_str_sensor, e_left_sensor,
        w_left_sensor, ns_sensor,             // traffic sensors, east-west str, east-west left, north-south
  output colors e_str_light, w_str_light, e_left_light, w_left_light, ns_light);     // traffic lights, east-west str, east-west left, north-south

  logic s, sb, e, eb, w, wb, l, lb, n, nb;	 // shorthand for traffic combinations:

  assign s  = e_str_sensor || w_str_sensor;					 // str E or W
  assign sb = e_left_sensor || w_left_sensor || ns_sensor;			     // 4 directions which conflict with s
  assign e  = e_str_sensor || e_left_sensor;
  assign eb = w_str_sensor || ns_sensor || w_left_sensor;
  assign w  = w_str_sensor || w_left_sensor;
  assign wb = e_str_sensor || e_left_sensor || ns_sensor;
  assign l  = w_left_sensor || e_left_sensor;
  assign lb = w_str_sensor || e_str_sensor || ns_sensor;
  assign n  = ns_sensor;
  assign nb = w_str_sensor || w_left_sensor || e_str_sensor || e_left_sensor;
/* fill in the remaining definitions
*/

// 20 suggested states, 4 per direction   Y, Z = easy way to get 2-second yellows
// HRRRR = red-red following ZRRRR; ZRRRR = second yellow following YRRRR;
// RRRRH = red-red following RRRRZ;
  typedef enum {GRRRR, YRRRR, ZRRRR, HRRRR, 	           // ES+WS
  	            RGRRR, RYRRR, RZRRR, RHRRR, 			   // EL+ES
	            RRGRR, RRYRR, RRZRR, RRHRR,				   // WL+WS
	            RRRGR, RRRYR, RRRZR, RRRHR, 			   // WL+EL
	            RRRRG, RRRRY, RRRRZ, RRRRH} tlc_states;    // NS
	tlc_states    present_state, next_state;
	integer ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
			ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
	if(reset) begin
	  present_state <= RRRRH;
	  ctr5          <= 0;
	  ctr10         <= 0;
  end
	else begin
	  present_state <= next_state;
	  ctr5          <= next_ctr5;
	  ctr10         <= next_ctr10;
	end

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
	next_state = RRRRH;                            // default to reset state
	next_ctr5  = 0; 							   // default: reset counters
	next_ctr10 = 0;
	case(present_state)
/* ************* Fill in the case statements ************** */
	  GRRRR: begin
          if (ctr5 == 4 || ctr10 == 9) begin
              next_state = YRRRR;
              next_ctr5 = 0;
              next_ctr10 = 0;
          end else begin
              next_state = GRRRR;
          end

          if (!s || ctr5) begin
              next_ctr5 = ctr5 + 1;
          end

          if ((s && sb) || ctr10) begin
              next_ctr10 = ctr10 + 1;
          end
      end

	 YRRRR: begin
         next_state = ZRRRR;
     end

    ZRRRR: begin
        next_state = HRRRR;
    end

	  HRRRR: begin                                  // **fill in the blanks in the if ... else if ... chain
	      if (e) begin
		    next_state = RGRRR;	                         // ES+EL green
		  end else if (w) begin
		    next_state = RRGRR;							 // WS+WL green
		  end else if (l) begin
		    next_state = RRRGR;							 // WL+EL green
		  end else if (n) begin
		    next_state = RRRRG;							 // NS green
          end else if (s) begin
		    next_state = GRRRR;
		  end else begin
		    next_state = HRRRR;
          end
    end

	  RGRRR: begin 		                                 // EL+ES green


          if (ctr5 == 4 || ctr10 == 9) begin
              next_state = RYRRR;
              next_ctr5 = 0;
              next_ctr10 = 0;
          end else begin
              next_state = RGRRR;
          end

          if (!e || ctr5) begin
              next_ctr5 = ctr5 + 1;
          end

          if ((e && eb) || ctr10) begin
              next_ctr10 = ctr10 + 1;
          end
	  end

	  RYRRR: begin
          next_state = RZRRR;
      end

	  RZRRR: begin
          next_state = RHRRR;
      end

	  RHRRR: begin
      if (w) begin
        next_state = RRGRR;	                         // ES+EL green
      end else if (l) begin
        next_state = RRRGR;							 // WS+WL green
      end else if (n) begin
        next_state = RRRRG;							 // WL+EL green
      end else if (s) begin
        next_state = GRRRR;							 // NS green
      end else if (e) begin
        next_state = RGRRR;
      end else begin
        next_state = RHRRR;
      end
    end

	  RRGRR: begin


          if (ctr5 == 4 || ctr10 == 9) begin
              next_state = RRYRR;
              next_ctr5 = 0;
              next_ctr10 = 0;
          end else begin
              next_state = RRGRR;
          end

          if (!w || ctr5) begin
              next_ctr5 = ctr5 + 1;
          end

          if ((w && wb) || ctr10) begin
              next_ctr10 = ctr10 + 1;
          end
	  end

    RRYRR: begin
        next_state = RRZRR;
    end

	  RRZRR: begin
          next_state = RRHRR;
      end

	  RRHRR: begin
      if (l) begin
        next_state = RRRGR;	                         // ES+EL green
      end else if (n) begin
        next_state = RRRRG;							 // WS+WL green
      end else if (s) begin
        next_state = GRRRR;							 // WL+EL green
      end else if (e) begin
        next_state = RGRRR;							 // NS green
      end else if (w) begin
        next_state = RRGRR;
      end else begin
        next_state = RRHRR;
      end
    end

    RRRGR: begin


        if (ctr5 == 4 || ctr10 == 9) begin
            next_state = RRRYR;
            next_ctr5 = 0;
            next_ctr10 = 0;
        end else begin
            next_state = RRRGR;
        end

        if (!l || ctr5) begin
            next_ctr5 = ctr5 + 1;
        end

        if ((l && lb) || ctr10) begin
            next_ctr10 = ctr10 + 1;
        end
	  end

    RRRYR: begin
        next_state = RRRZR;
    end

	  RRRZR: begin
          next_state = RRRHR;
      end

	  RRRHR: begin
      if (n) begin
        next_state = RRRRG;	                         // ES+EL green
      end else if (s) begin
        next_state = GRRRR;							 // WS+WL green
      end else if (e) begin
        next_state = RGRRR;							 // WL+EL green
      end else if (w) begin
        next_state = RRGRR;							 // NS green
      end else if (l) begin
        next_state = RRRGR;
      end else begin
        next_state = RRRHR;
      end
    end

    RRRRG: begin


        if (ctr5 == 4 || ctr10 == 9) begin
            next_state = RRRRY;
            next_ctr5 = 0;
            next_ctr10 = 0;
        end else begin
            next_state = RRRRG;
        end

        if (!n || ctr5) begin
            next_ctr5 = ctr5 + 1;
        end

        if ((n && nb) || ctr10) begin
            next_ctr10 = ctr10 + 1;
        end
	  end

    RRRRY: begin
        next_state = RRRRZ;
    end

	  RRRRZ: begin
          next_state = RRRRH;
      end

	  RRRRH: begin
          if (s) begin
            next_state = GRRRR;	                         // ES+EL green
          end else if (e) begin
            next_state = RGRRR;							 // WS+WL green
          end else if (w) begin
            next_state = RRGRR;							 // WL+EL green
          end else if (l) begin
            next_state = RRRGR;							 // NS green
          end else if (n) begin
            next_state = RRRRG;
          end else begin
            next_state = RRRRH;
          end
        end
    endcase

  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
	always_comb begin
	  e_str_light  = red;                // cover all red plus undefined cases
	  w_str_light  = red;				 // no need to list them below this block
	  e_left_light = red;
	  w_left_light = red;
	  ns_light     = red;
	  case(present_state)      // Moore machine
        // GREEN
		GRRRR:   begin e_str_light = green;
					   w_str_light = green;
		end

        RGRRR: begin
            e_left_light = green;
            e_str_light = green;
        end

        RRGRR: begin
            w_left_light = green;
            w_str_light = green;
        end

        RRRGR: begin
            e_left_light = green;
            w_left_light = green;
        end

        RRRRG: begin
            ns_light = green;
        end

        // YELLOW

        YRRRR:   begin e_str_light = yellow;
					   w_str_light = yellow;
		end

        RYRRR: begin
            e_left_light = yellow;
            e_str_light = yellow;
        end

        RRYRR: begin
            w_left_light = yellow;
            w_str_light = yellow;
        end

        RRRYR: begin
            e_left_light = yellow;
            w_left_light = yellow;
        end

        RRRRY: begin
            ns_light = yellow;
        end

        // YELLOW Z case
        ZRRRR:   begin e_str_light = yellow;
                       w_str_light = yellow;
        end

        RZRRR: begin
            e_left_light = yellow;
            e_str_light = yellow;
        end

        RRZRR: begin
            w_left_light = yellow;
            w_str_light = yellow;
        end

        RRRZR: begin
            e_left_light = yellow;
            w_left_light = yellow;
        end

        RRRRZ: begin
            ns_light = yellow;
        end
      endcase
      // ** fill in the guts for all 5 directions -- just the greens and yellows **
	end

endmodule
