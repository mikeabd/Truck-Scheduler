/*********************************************
 * OPL 12.6.0.0 Model
 * Author: mike.barough
 * Creation Date: Apr 01, 2016 at 11:10:17 AM
 *********************************************/

/********************************************************************************************
 * Initial input parameters for the Model:													*
 * Initial String Holding the Raw Input Data SQL Query: sqlQueryString1  					*
 * Maximum Number of Teams: MaxTeam															*
 * Minimum Mileage for Each Team: MinMiles													*
 * Maximum Mileage for Each Team: MaxMiles													*
 * DoT Minimum Buffer Time for Each Team: DOT_Const											*
 * Maximum Number of Solutions Kept in the CPLEX Solution Pool: SolutionPoolCapacity 		*
 * Parameter for MIP Duality Gap: DualGap													*
 																							*
 * MIP Objective Function Penalty Costs:													*
 * Cost for Opening a Team : p1																*
 * Penalty Cost per Mile for a Team's Mileage Shortage (Driving Less than 4500): p2			*
 * Penalty Cost per Mile for a Team's Mileage Surplus (Driving Over 4500): p3   			*
 * Penalty Cost per Change for a Team at Route Level: p4 									*
 * Penalty Cost per Change for a Team at Team Level: p5										*
 																							*
 * MIP Constraints Parameters:																*
 * Maximum Allowed Changes at Route Level: AllowedRouteTeamChanges							*
 * Maximum Allowed Changes at Team Level: AllowedTeamChanges								*
 																							*
 * MIP Over-Writting Constraints' Parameters:												*
 * Parameter to Allow Change Restrictions at Team Level or Team_Route Level:				*
 *	OW_1 (1 = Team Changes, 0 = Route-Team Changes)											* 
 * Parameter to Force Opening all Current Existing Teams: OW_2 (1 = Active, 0 = Diactive)	*
 * Parameter to Force Route Assignments to Selected Teams: OW_3 (1 = Active, 0 = Diactive)	*
 *******************************************************************************************/

string sqlQueryString1 = ...;
int Time_Horizon = 60*24*7-1;
int MaxTeam = ...;     
int MinMiles = ...;
int MaxMiles = ...;
int DOT_Const = ...;
int SolutionPoolCapacity = ...;
float DualGap = ...;
float p1 = ...;
float p2 = ...;
float p3 = ...;
float p4 = ...;
float p5 = ...;
int AllowedRouteTeamChanges = ...;
int AllowedTeamChanges = ...;
int OW_1 = ...;
int OW_2 = ...;
int OW_3 = ...;

/********************************************************************************************
* PreProcessing Custom Built Functions:														*
* TimeCalc(): Calculates the time (in this case it is seconds) and takes one input argumet	*
* that is Date() which is a TimeDate function in ILOG IDE									*
* ToWConversion(): Convertes Day of Week (DoW) and Tiem of Day (ToD) to an integer			*
* equivalent number and it takes 2 arguments DoW and ToW									*
********************************************************************************************/

include "NLC_Driver_Scheduler_Modified_Functions.mod";

/* Initial Tuple for Holding the Raw Data */
tuple Routes_RawData{
	int route_number;
	int team_number;
	string carrier;
	string from_loc;
	string to_loc;
	string dispatch_DoW;
	float dispatch_ToD;
	string arrival_DoW;
	float arrival_ToD;
	string release_DoW;
	float release_ToD;
	float miles;
	string status;
	int TeamNumOldOrg;
    string CarrierOldOrg;
    int fixed;
}; 

{Routes_RawData} Route = ...; 	

/* Initial Indexed Tuple for Holding the Raw Data */ 
tuple Routes_Arc_Indexed{
	int arc_id;
	int arc_route;
	int route_number;
	int team_number;
	string carrier;
	string from_loc;
	string to_loc;
	string dispatch_DoW;
	float dispatch_ToD;
	string arrival_DoW;
	float arrival_ToD;
	string release_DoW;
	float release_ToD;
	float miles;
	string status;
	int TeamNumOldOrg;
    string CarrierOldOrg;
    int fixed;
}; 

sorted {int} routes = {route | <route, t_n, c, f_l, t_l, dis_dow, dis_tod, arr_dow, arr_tod, rel_dow, rel_tod, m, s, t_n_o, c_o, f> in Route};

int arc_ind;
int RouteArc[routes];
float RouteTotalMiles[routes];
float TotalMiles;

{Routes_Arc_Indexed} Route_Arc_A;

/* Assigning Arc Numbers to Routes */
execute{
 	 for(var a in Route){
 		for(var b in routes){
 			if(a.route_number == b){
 		 		arc_ind = arc_ind + 1;
 		 		RouteArc[b] = RouteArc[b] + 1 ;
 		 		RouteTotalMiles[b] = RouteTotalMiles[b] + a.miles ;
 		 		Route_Arc_A.add(arc_ind, RouteArc[b], b, a.team_number, a.carrier, a.from_loc, a.to_loc, a.dispatch_DoW, a.dispatch_ToD
 		 			, a.arrival_DoW, a.arrival_ToD, a.release_DoW, a.release_ToD , Opl.ceil(a.miles), a.status, a.TeamNumOldOrg
 		 			, a.CarrierOldOrg, a.fixed);	 	 		 			
 			}
 		}	
 	}	
 	for(var c in Route){
 		TotalMiles = TotalMiles + c.miles ;
 	}
}

sorted {int} Teams = {t_n | <r, t_n, carrier, f_l, t_l, dis_dow, dis_tod, arr_dow, arr_tod, rel_dow, rel_tod,
							 m, s, t_n_o, c_o, f> in Route};

tuple Routes_Arc_Team_Indexed{
	int arc_id;
	int arc_route;
	int route_number;
	int team_number;
	int team_ind;
	string carrier;
	string from_loc;
	string to_loc;
	string dispatch_DoW;
	float dispatch_ToD;
	string arrival_DoW;
	float arrival_ToD;
	string release_DoW;
	float release_ToD;
	float miles;
	string status;
	int TeamNumOldOrg;
    string CarrierOldOrg;
    int fixed;
}; 

{Routes_Arc_Team_Indexed} Route_Arc;

/* Assigning a Team Index to Routes */ 
execute{	
	var team_ind;
	team_ind = 0;
	for(var i in Teams){
		team_ind++;
		for(var j in Route_Arc_A){
			if(j.team_number == i){
				Route_Arc.add(j.arc_id, j.arc_route, j.route_number, j.team_number, team_ind, j.carrier, j.from_loc
					, j.to_loc, j.dispatch_DoW, j.dispatch_ToD, j.arrival_DoW, j.arrival_ToD, j.release_DoW
					, j.release_ToD, j.miles, j.status, j.TeamNumOldOrg, j.CarrierOldOrg, j.fixed);
			}
		}
	}
	MaxTeam = Opl.maxl(team_ind + 10, MaxTeam);
	writeln("*********************************************************************");
	writeln("****** Algorithm Began with ", Opl.last(routes), " Routes ");
	writeln("****** Total Available Teams of ", MaxTeam, " Teams ", "at ", Date());		
	writeln("*********************************************************************");
}

/* Fixed Team - Route Assignments */
tuple fixed_assign{
	int route_number;
	int team_number;
	int team_ind;
}

{fixed_assign} FixedAssignments;

execute{
	for(var i in Route_Arc){
		if(i.fixed == 1){
			FixedAssignments.add(i.route_number, i.team_number, i.team_ind);
		}
	}
}

tuple Routes_Arc_ToW{
	int arc_id;
	int arc_route;
	int route_number;
	int team_number;
	int team_ind;
	string carrier;
	string from_loc;
	string to_loc;
	string dispatch_DoW;
	float dispatch_ToD;
	int dispatch_ToW;
	string arrival_DoW;
	float arrival_ToD;
	int arrival_ToW;
	string release_DoW;
	float release_ToD;
	int release_ToW;
	float miles;
	string status;
	int TeamNumOldOrg;
    string CarrierOldOrg;
}; 

{Routes_Arc_ToW} Route_Arc_ToW;

/************************ Building the Master Set with Time of the Week (TOW) **********************/
tuple team_ind_attr{
	int team_ind;
	int old_team_num;
	string old_team_carrier;
}

{team_ind_attr} Team_Attribute;

int btime_Heuristic;
int Team_Att_Num[1..MaxTeam];
string Team_Att_Carr[1..MaxTeam];

execute{
	writeln("*********************************************************************");
	writeln("****** Sorting Algorithm Began");
	btime_Heuristic = TimeCalc(new Date());
	for(var i in Route_Arc){
		Route_Arc_ToW.add(i.arc_id, i.arc_route, i.route_number, i.team_number, i.team_ind, i.carrier, i.from_loc
			, i.to_loc, i.dispatch_DoW, i.dispatch_ToD, ToWConversion(i.dispatch_DoW, i.dispatch_ToD), i.arrival_DoW
			, i.arrival_ToD, ToWConversion(i.arrival_DoW, i.arrival_ToD), i.release_DoW, i.release_ToD
			, ToWConversion(i.release_DoW, i.release_ToD), i.miles, i.status, i.TeamNumOldOrg, i.CarrierOldOrg);
						
		Team_Attribute.add(i.team_ind, i.TeamNumOldOrg, i.CarrierOldOrg);
		var temp = i.team_ind;
	}
	
	for(var j = temp + 1 ; j <= MaxTeam ; j++){
		Team_Attribute.add(j, 99, "NEW");
	}

	for(var z in Team_Attribute){
		Team_Att_Num[z.team_ind] = z.old_team_num;
		Team_Att_Carr[z.team_ind] = z.old_team_carrier;	
	}
}

tuple route_f_l {
	int route;
	int route_ToW;
}

{route_f_l} first_arc_time;
{route_f_l} last_arc_time;

/* First and Last Arc for a Route */
execute{
	for (var i in routes){
		for (var j in Route_Arc_ToW){
			if (i == j.route_number){
				if (j.arc_route == RouteArc[i]){
					last_arc_time.add(i, j.release_ToW);	
				} 		
  				if (j.arc_route == 1){
  					first_arc_time.add(i, j.dispatch_ToW);	
  				}
  			}			 								
		}	
	}
}

int dummy_dispatch_ToW[routes];
int dummy_ord_route[routes];
int last_route = last(routes);

tuple sorted_route_f_l {
	int ind;
	int route;
	int route_ToW;
}

{sorted_route_f_l} sorted_first_arc_time;

tuple sorted_route_ToW{
	int ind;
	int route;
	int route_dispatch_ToW;
	int route_arrival_ToW;
	float miles;
	string state;
}

{sorted_route_ToW} sorted_route_f_l_time;

int Arr_Size;

/* Sorting Routes According to their Dispatch Time */
execute{
	var bTime = TimeCalc(new Date());
	var temp_dispatch_ToW;
	var temp_ord_route;
	
	for(var i in first_arc_time){
		dummy_dispatch_ToW[i.route] = i.route_ToW;
		dummy_ord_route[i.route] = i.route;
	}
	for(var j = 1 ; j <= last_route-1 ; j++){
		for(var k = 1 ; k <= last_route-j ; k++){
			if(dummy_dispatch_ToW[k] >= dummy_dispatch_ToW[k+1]){
				temp_dispatch_ToW = dummy_dispatch_ToW[k];
				dummy_dispatch_ToW[k] = dummy_dispatch_ToW[k+1];
				dummy_dispatch_ToW[k+1] = temp_dispatch_ToW;							
				temp_ord_route = dummy_ord_route[k];
				dummy_ord_route[k] = dummy_ord_route[k+1];
				dummy_ord_route[k+1] = temp_ord_route;
			}
		}
	}
	for(i=1 ; i <= last_route ; i++){
		sorted_first_arc_time.add(i, dummy_ord_route[i], dummy_dispatch_ToW[i]);		
	}
	for(i in sorted_first_arc_time){
		for(j in last_arc_time){
			if(i.route == j.route){
				sorted_route_f_l_time.add(i.ind, i.route, i.route_ToW, j.route_ToW, RouteTotalMiles[i.route], "Route");					
			}
		}
	}
	Arr_Size = sorted_route_f_l_time.size;
	var eTime = TimeCalc(new Date());
	var totalTime = eTime - bTime;
	writeln("****** Sorting Ended with Total Time of ", totalTime , " Seconds");
	writeln("*********************************************************************");
}

/*************************** Creating DoT Dummies *************************/
tuple dummy_set{
	int ind;
	int r_ind;
	int original_ind;
	int dummy_start;
	int dummy_end;
}

{dummy_set} WeekDay_DoTDummy;
{dummy_set} WeekEnd_DoTDummy;
int TotalDummies;

execute{
	var temp_ind_WD = 0;
	var temp_ind_WE = 0;
	var temp = 0;
	var temp_ind = 0;
	for(var i in sorted_route_f_l_time){
		for(var j = 1 ; j <= MaxTeam ; j++){
			temp = i.route_arrival_ToW + DOT_Const;
			temp_ind = temp_ind + 1;
			if(temp < 10079){
				temp_ind_WD = temp_ind_WD + 1;
				WeekDay_DoTDummy.add(temp_ind_WD, i.route, temp_ind, i.route_arrival_ToW, i.route_arrival_ToW + DOT_Const);
			}
			else{
				temp_ind_WE = temp_ind_WE + 1;
				WeekEnd_DoTDummy.add(temp_ind_WE, i.route, temp_ind, i.route_arrival_ToW, i.route_arrival_ToW + DOT_Const - Time_Horizon);			
			}	
		}
	}
	TotalDummies = WeekDay_DoTDummy.size + WeekEnd_DoTDummy.size;
}

/************************* Route Gap Matrix **********************************/
int RouteGapMins[routes][routes];
int temp_dispatch_ToW[routes];
int temp_arrival_ToW[routes];

execute{
	for(var k in sorted_route_f_l_time){
		temp_dispatch_ToW[k.route] = k.route_dispatch_ToW;
		temp_arrival_ToW[k.route] = k.route_arrival_ToW;
	}
		
	for(var i = 1 ; i <= Opl.last(routes) ; i++){
		for(var j = 1 ; j <= Opl.last(routes) ; j++){
			RouteGapMins[i][j] = 1000;
		}
 	}			
		
	for(var i = 1 ; i <= Opl.last(routes) ; i++){
		for(var j = i+1 ; j <= Opl.last(routes) ; j++){
			if(temp_dispatch_ToW[i] > temp_arrival_ToW[i] && temp_arrival_ToW[j] > temp_dispatch_ToW[j]){
				if(temp_dispatch_ToW[j] >= temp_arrival_ToW[i] && temp_dispatch_ToW[i] >= temp_arrival_ToW[j]){
					RouteGapMins[i][j] = temp_dispatch_ToW[j] - temp_arrival_ToW[i] ;
					RouteGapMins[j][i] = temp_dispatch_ToW[j] - temp_arrival_ToW[i] ;			
				}				
			} 
			if(temp_dispatch_ToW[i] < temp_arrival_ToW[i] && temp_arrival_ToW[j] > temp_dispatch_ToW[j]){
				if(temp_dispatch_ToW[j] >= temp_arrival_ToW[i]){
					RouteGapMins[i][j] = temp_dispatch_ToW[j] - temp_arrival_ToW[i] ;
					RouteGapMins[j][i] = temp_dispatch_ToW[j] - temp_arrival_ToW[i] ;
				}				
			}	 
		}
	}
}

/**************************************** Current State Matrix ****************************/
int TotalNbrCurrentTeams;
sorted {int} current_team_index = {t_i | <a_i, a, r, t_n, t_i, c, f_l, t_l, dis_dow, dis_tod, arr_dow, arr_tod
					, rel_dow, rel_tod, m, s, t_n_o, c_o, f> in Route_Arc : s == "CurrentSchedule"};
execute{
	TotalNbrCurrentTeams = current_team_index.size;
}

int Current_Schedule_Set[routes];
int Team_Org_Ind[1..TotalNbrCurrentTeams];
int Current_Team_Route[current_team_index][routes];
int Current_Team_Route_Ext[1..MaxTeam][routes];

tuple schedule{
	int team_ind;
	int team_original_ind;
	int number_of_components;
	int current_schedule_set[routes];
	float set_mile;
	int TeamNumOldOrg;
    string CarrierOldOrg;
}

{schedule} Current_Schedule;

int Current_Schedule_Size;

execute{
	writeln("*********************************************************************");
	writeln("****** Current State Matrix Building Began ");
	btime_Heuristic = TimeCalc(new Date());

	var temp_miles;
	var temp_comp;
	var temp_TeamNumOld;
	var temp_CarrierOld;
	var bTime = TimeCalc(new Date());
	for(var k in current_team_index){			
		temp_miles = 0;
		temp_comp = 0;
		for(var j = 1 ; j <= Opl.last(routes) ; j++){
			Current_Schedule_Set[j] = 0;
		}
		for(var i in Route_Arc){
			if(i.status == "CurrentSchedule" && k == i.team_ind){
				Team_Org_Ind[k] = i.team_number;
				for(var z in sorted_route_f_l_time){
					if(z.route == i.route_number){
						Current_Schedule_Set[z.ind] = 1;
						Current_Team_Route[k][z.ind] = 1;
						temp_miles = temp_miles + i.miles;
						temp_TeamNumOld = i.TeamNumOldOrg;
						temp_CarrierOld = i.CarrierOldOrg;					
					}				
				}	
			}		
		}
		for(var z = 1 ; z <= Opl.last(routes) ; z++){
			if(Current_Schedule_Set[z] == 1){
				temp_comp++;			
			}		
		}
		Current_Schedule.add(k, Team_Org_Ind[k], temp_comp, Current_Schedule_Set, temp_miles
			, temp_TeamNumOld, temp_CarrierOld);
	}

	for(var y = 1 ; y <= MaxTeam ; y++){
		for(var u = 1 ; u <= current_team_index.size ; u++){
			if(y == u){			
				for(var j = 1 ; j <= Opl.last(routes) ; j++){
					Current_Team_Route_Ext[y][j] = Current_Team_Route[y][j];			
				}
			}
		}
	}

	Current_Schedule_Size = Current_Schedule.size;
	var eTime = TimeCalc(new Date());
	var totalTime = eTime - bTime;
	writeln("****** Current State Matrix Building Ended with Total Time of ", totalTime , " Seconds");
	writeln("*********************************************************************");
}

/* Segregating Weekday and Weekend Routes */
tuple sorted_segrigated_route_ToW{
	int ind;
	int original_ind;
	int route;
	int route_dispatch_ToW;
	int route_arrival_ToW;
	float miles;
	string state;
}

{sorted_segrigated_route_ToW} WeekEnd_Routes;
{sorted_segrigated_route_ToW} WeekDay_Routes;
{sorted_segrigated_route_ToW} WeekEnd_WeekDay_Routes;

execute{
	writeln("*********************************************************************");
	writeln("****** Segrigating Weekend and Weekday Routes Began");
	btime_Heuristic = TimeCalc(new Date());
	var bTime = TimeCalc(new Date());
	var j = 1;
	var k = 1;
	for(var i in sorted_route_f_l_time){
		if(i.route_arrival_ToW < i.route_dispatch_ToW){
			WeekEnd_Routes.add(j, i.ind, i.route, i.route_dispatch_ToW, i.route_arrival_ToW, i.miles, i.state);
			j = j + 1;
		}
		else{
			WeekDay_Routes.add(k, i.ind, i.route, i.route_dispatch_ToW, i.route_arrival_ToW, i.miles, i.state);
			k = k + 1;
		}	
	}
	for(var z in WeekEnd_Routes){
		WeekEnd_WeekDay_Routes.add(k, z.original_ind, z.route, z.route_dispatch_ToW, z.route_arrival_ToW
			, z.miles, i.state);
		k = k + 1;
	}
	
	var eTime = TimeCalc(new Date());
	var totalTime = eTime - bTime;
	writeln("****** Route Segregating Ended with Total Time of ", totalTime , " Seconds");
	writeln("*********************************************************************");
}

range indTeams = 1..MaxTeam;
range indTotalRoutes = 1..Arr_Size;
range indDummy = 1..TotalDummies;

/* Solution Pool Summary Tuple in the Main Block */
tuple Solution_Pool{
	key int sol_num;
	float sol_obj;
	float total_teams;
	float mile_slack[indTeams];
	float mile_surplus[indTeams];
	float team_route_changes;
	float team_changes;
}

{Solution_Pool} Sol_Summary;

/* Solution Pool Tuple for Route-Team Assignment at Main Block*/ 
tuple Solution_RouteTeam{
	int sol_num;
	int team;
	int route;
}

{Solution_RouteTeam} RouteTeamAssignment;

tuple Solution_RouteTeamEliAdd{
	int sol_num;
	int team;
	int route;
	string check;
}

{Solution_RouteTeamEliAdd} RouteTeamEliAdd;


/* Solution Pool Tuple for DoT Dummy at Main Block */
tuple Solution_DummyTeam{
	int sol_num;
	int team;
	int dummy;
}

{Solution_DummyTeam} DummyTeamAssignment;

main{
	cplex.solnpoolcapacity = thisOplModel.SolutionPoolCapacity;
	cplex.rootalg = 0;
	cplex.nodealg = 0;
	cplex.mipsearch = 0;
	cplex.cliques = 1;
	cplex.covers = 1;
	cplex.mircuts = 0;
	cplex.epgap = thisOplModel.DualGap; 
  	cplex.threads = 4;
  	cplex.nodefileind = 3;
  	cplex.trelim = 7000000;
  	cplex.workmem = 300000;
  	cplex.startalg = 4;
  	cplex.probe = 3;
  	cplex.mipordind = true;
  	cplex.mipemphasis = 0; 
  	cplex.memoryemphasis = true;
  	cplex.tuningdisplay = 2;
	thisOplModel.generate();
	cplex.solve();	
	if(cplex.populate()){
		var nsolns = cplex.solnPoolNsolns;
		var z1 = new Array();
		var z2 = new Array();
		var z3 = new Array();
		var z4 = new Array();
		var totalteams = 0 ;
		var milage_slack = new Array() ;
		var milage_surplus = new Array();
		var teamroutechange = 0;
		var teamchange = 0;
		for(var s = 0 ; s < nsolns ; s++){
			thisOplModel.setPoolSolution(s);	
			milage_slack = thisOplModel.Team_slack.solutionValue ;
			writeln("milage_slack =  ", milage_slack);
			milage_surplus = thisOplModel.Team_surplus.solutionValue ;
			writeln("milage_surplus =  ", milage_surplus);
			teamroutechange = thisOplModel.TeamRouteChanges.solutionValue ;
			writeln("TeamRouteChange =  ", teamroutechange);
			totalteams = thisOplModel.TotalTeams.solutionValue;
			writeln("TotalTeams =  ", totalteams);
			teamroutechange = thisOplModel.TeamRouteChanges.solutionValue;
			writeln("TeamRouteChange =  ", teamroutechange);
			teamchange = thisOplModel.TeamChanges.solutionValue;
			writeln("TeamChange =  ", teamchange);
			thisOplModel.Sol_Summary.add(s, cplex.getObjValue(s), totalteams, milage_slack
					, milage_surplus, teamroutechange, teamchange);
		}
		
		for(var s = 0 ; s < nsolns ; s++){
			thisOplModel.setPoolSolution(s);
			z1 = thisOplModel.RouteTeamAssign.solutionValue ;
			for(var i = 1 ; i <= thisOplModel.MaxTeam ; i++){
				for(var j = 1 ; j <= thisOplModel.Arr_Size ; j++){
					if(z1[i][j] == 1){
						thisOplModel.RouteTeamAssignment.add(s, i, j);				
					}				
				}			
			}
			z2 = thisOplModel.DummyTeamAssign.solutionValue ;	
			for(i = 1 ; i <= thisOplModel.MaxTeam ; i++){
				for(j = 1 ; j <= thisOplModel.TotalDummies ; j++){
					if(z2[i][j] == 1){
						thisOplModel.DummyTeamAssignment.add(s, i, j);					
					}				
				}			
			}
			z3 = thisOplModel.RouteElimination.solutionValue ;	
			z4 = thisOplModel.RouteAddition.solutionValue ;
			for(i = 1 ; i <= thisOplModel.MaxTeam ; i++){
				for(j = 1 ; j <= thisOplModel.Arr_Size ; j++){
					if(z3[i][j] == 1){
						thisOplModel.RouteTeamEliAdd.add(s, i, j, "Elimination");					
					}
					if(z4[i][j] == 1){
						thisOplModel.RouteTeamEliAdd.add(s, i, j, "Addition");					
					}				
				}			
			}
		}
	}
	writeln("Population= ", cplex.PopulateLim);
	writeln("PoolCapacity = " , cplex.solnpoolcapacity);
	
	writeln("CPLEX Status = ", cplex.status);
	if(cplex.status == 128){
		thisOplModel.postProcess();
		writeln("CPLEX Status = Feasibility");
	}
	
	if(cplex.status == 3){
		writeln("CPLEX Status =  Infeasible");	
	}
	
	writeln("Run Time Was = ", cplex.getCplexTime(), " Seconds"); 
}

/****************************************************************************************************
* MIP Decision Variables:																			*			
* Assignment of a Route to a Team: RouteTeamAssign[][]												*
* Assignment of a Dummy to a Team: DummyTeamAssign[][]												*
* Decision Over Opening a Team: Team[]																*
* Auxiliary Variable for each Team's Slack Mileage: Team_slack[]									*
* Auxiliary Variable for each Team's Surplus Mileage: Team_surplus[]								*
* Auxiliary Variable for Calculating Changes at Route Level: NumChange[][]							*
* Auxiliary Variable for Calculating Changes at Team Level: TeamChange[]							*
* Auxiliary Decision Variable for Tracking each Team's Route Elimination: RouteElimination[][] 		*
* Auxiliary Decision Variable for Tracking each Team's Route Addition: RouteAddition[][]			*
																									*
* MIP Constraints:																					*
* ct_1: Routes Single Sourcing Constraint															*
* ct_2: Each Team Can Have at Most One Weekend Route												*
* ct_3: If One Weekend Route is Assigned to a Team All other Weekend Assignments should be 0		*
* ct_4: If a Weekend Route is Assigned Weekday Overlaps With the Weekend Route Needs to be 0		*
* ct_5: If a Weekday Route is Assigned all other Weekday Route's Overlaps Needs to be 0 			*
** DoT Dummy Constraints																			*
* ct_6: Each Team Can have a Weekday or a Weekend DoT Dummy But not Both							*
* ct_7: No DoT Dummy for Teams With Only 1 Route													*
* ct_8: Teams with Multiple Routes Should have a DoT Dummy											*
* ct_9: No DoT Dummy when the Team is not Open														*
* ct_10: DoT Dummy Must Not Overlap with any Weekday Routes											*
* ct_11: No Weekday DoT Dummy Can Overlap with a Weekend Route										*
* ct_12: A Weekend DoT Dummy Must not Overlap with any Weekday Routes								*
* ct_13: There Cant be a Weekend Route and a Weekend DoT Dummy Assigned at the Same Time to a Team	*
** Min-Max Milage Constraints and Linking Constraints between Surplus-Slack and Teams				* 
* ct_14: Mileage Balance Constraint																	*
* ct_15: Max Mileage Constraint																		*
* ct_16: Linking Constraints																		*
* ct_17: Route Assignment and Teams Linking Constraint												*
* ct_18: Route-Team Assignment Change Calculations 													*
* ct_19: Team Change Calculation																	*
* ct_20: Route-Team Change Tracking at Route-Team Level												*
* ct_21: Maximum Number of Change Constraint (Route-Team Assignment Level)							*
* ct_22: Maximum Number of Changes Constraint (Team Level Changes)									*
* ct_23: Constraint to Keep all the Current Teams Open Regardless of Route Assignemt				*
* ct_24: Constraints to Force Route Assignments to Selected Teams									*
*****************************************************************************************************/

dvar boolean RouteTeamAssign[indTeams][indTotalRoutes];
dvar boolean DummyTeamAssign[indTeams][indDummy];
dvar boolean Team[indTeams];
dvar float+ Team_slack[indTeams];
dvar float+ Team_surplus[indTeams];
dvar boolean NumChange[indTeams][indTotalRoutes];
dvar boolean TeamChange[indTeams];
dvar boolean RouteElimination[indTeams][indTotalRoutes];
dvar boolean RouteAddition[indTeams][indTotalRoutes];

dexpr float TotalTeams = sum(t in indTeams) Team[t];
dexpr float TeamSlack = sum(t in indTeams) Team_slack[t];
dexpr float TeamSurplus = sum(t in indTeams) Team_surplus[t];
dexpr float TeamRouteChanges = sum(t in indTeams, r in indTotalRoutes) NumChange[t][r];
dexpr float TeamChanges = sum(t in indTeams) TeamChange[t];

minimize p1*TotalTeams + p2*TeamSlack + p3*TeamSurplus + p4*TeamRouteChanges + p5*TeamChanges;

subject to{
	
	ct_1:
		forall(r in sorted_route_f_l_time){
			sum(t in indTeams) RouteTeamAssign[t][r.route] == 1 ;
		}
 
	ct_2:
		forall(t in indTeams){
			sum(r_we in WeekEnd_Routes) RouteTeamAssign[t][r_we.route] <= 1 ;
		}
	
	ct_3:
		forall(t in indTeams, r_we in WeekEnd_Routes){
			RouteTeamAssign[t][r_we.route] == 1 => sum(r_we_p in WeekEnd_Routes : r_we.route != r_we_p.route)
				RouteTeamAssign[t][r_we_p.route] == 0 ;
		}

	ct_4:
		forall(t in indTeams, r_we in WeekEnd_Routes){
			RouteTeamAssign[t][r_we.route] == 1 =>
				sum(r_wd in WeekDay_Routes : r_wd.route_dispatch_ToW < r_we.route_arrival_ToW || r_wd.route_arrival_ToW > r_we.route_dispatch_ToW)
						RouteTeamAssign[t][r_wd.route] == 0 ;
		}

	ct_5:
		forall(t in indTeams, r_wd in WeekDay_Routes){
			RouteTeamAssign[t][r_wd.route] == 1 =>
				sum(r_wd_p in WeekDay_Routes : r_wd.route != r_wd_p.route && ( 
					(r_wd.route_dispatch_ToW <= r_wd_p.route_dispatch_ToW && r_wd_p.route_dispatch_ToW < r_wd.route_arrival_ToW && r_wd_p.route_arrival_ToW >= r_wd.route_arrival_ToW) 
					|| (r_wd.route_dispatch_ToW >= r_wd_p.route_dispatch_ToW && r_wd.route_dispatch_ToW < r_wd_p.route_arrival_ToW && r_wd_p.route_arrival_ToW <= r_wd.route_arrival_ToW)
					|| (r_wd.route_dispatch_ToW <= r_wd_p.route_dispatch_ToW && r_wd.route_arrival_ToW >= r_wd_p.route_arrival_ToW) ) )
						RouteTeamAssign[t][r_wd_p.route] == 0 ;
		}

	ct_6:
		forall(t in indTeams){
			Team[t] == 1 =>
				sum(d_r in WeekDay_DoTDummy) DummyTeamAssign[t][d_r.original_ind] + sum(d_e in WeekEnd_DoTDummy) DummyTeamAssign[t][d_e.original_ind] <= 1 ;
		}
	
	ct_7:
	forall(t in indTeams){
		Team[t] == 1 
			&& ( (sum(r_wd in WeekDay_Routes) RouteTeamAssign[t][r_wd.route] <= 1 && sum(r_we in WeekEnd_Routes) RouteTeamAssign[t][r_we.route] == 0 )
					|| (sum(r_we in WeekEnd_Routes) RouteTeamAssign[t][r_we.route] == 1 && sum(r_wd in WeekDay_Routes) RouteTeamAssign[t][r_wd.route] == 0) ) =>
							sum(d_r in WeekDay_DoTDummy) DummyTeamAssign[t][d_r.original_ind] + sum(d_e in WeekEnd_DoTDummy) DummyTeamAssign[t][d_e.original_ind] == 0 ;
		}

	ct_8:
	forall(t in indTeams){
		Team[t] == 1 
			&& (sum(r_wd in WeekDay_Routes) RouteTeamAssign[t][r_wd.route] >= 2 
					|| (sum(r_we in WeekEnd_Routes) RouteTeamAssign[t][r_we.route] == 1 && sum(r_wd in WeekDay_Routes) RouteTeamAssign[t][r_wd.route] >= 1 ) ) =>
						sum(d_r in WeekDay_DoTDummy) DummyTeamAssign[t][d_r.original_ind] + sum(d_e in WeekEnd_DoTDummy) DummyTeamAssign[t][d_e.original_ind] == 1 ;
		}	
	
	ct_9:
		forall(t in indTeams){
			Team[t] == 0 =>
				sum(d_r in WeekDay_DoTDummy) DummyTeamAssign[t][d_r.original_ind] + sum(d_e in WeekEnd_DoTDummy) DummyTeamAssign[t][d_e.original_ind] == 0 ;
		}
	
	ct_10:
		forall(t in indTeams, r_wd in WeekDay_Routes){
			RouteTeamAssign[t][r_wd.route] == 1 => 
				sum(d in WeekDay_DoTDummy : (d.dummy_start >= r_wd.route_dispatch_ToW && d.dummy_end < r_wd.route_arrival_ToW) 
					|| (d.dummy_start >= r_wd.route_dispatch_ToW && d.dummy_start < r_wd.route_arrival_ToW) 
					|| (d.dummy_end > r_wd.route_dispatch_ToW && d.dummy_end <= r_wd.route_arrival_ToW)
					|| (d.dummy_start < r_wd.route_arrival_ToW && d.dummy_end >= r_wd.route_arrival_ToW)) DummyTeamAssign[t][d.original_ind] == 0 ;
		}
	
	ct_11:
		forall(t in indTeams, r_we in WeekEnd_Routes){
			RouteTeamAssign[t][r_we.route] == 1 => sum(d in WeekDay_DoTDummy: d.dummy_end > r_we.route_dispatch_ToW
				|| r_we.route_arrival_ToW > d.dummy_start || d.dummy_start > r_we.route_dispatch_ToW ) DummyTeamAssign[t][d.original_ind] == 0 ;	
		}
	
	ct_12:
		forall(t in indTeams, r_wd in WeekDay_Routes){
			RouteTeamAssign[t][r_wd.route] == 1 => sum(d in WeekEnd_DoTDummy : d.dummy_start < r_wd.route_arrival_ToW || d.dummy_end > r_wd.route_dispatch_ToW)
				DummyTeamAssign[t][d.original_ind] == 0 ;
		}
	
	ct_13:
		forall(t in indTeams, r_we in WeekEnd_Routes){
	  		RouteTeamAssign[t][r_we.route] == 1 => sum(d in WeekEnd_DoTDummy) DummyTeamAssign[t][d.original_ind] == 0 ;
		}

	forall(t in indTeams){
	ct_14:
		sum(r in sorted_route_f_l_time) (RouteTeamAssign[t][r.route] * r.miles) == MinMiles*Team[t] - Team_slack[t] + Team_surplus[t] ;
	
	ct_15:
		sum(r in sorted_route_f_l_time) (RouteTeamAssign[t][r.route] * r.miles) <= MaxMiles ;
		
	ct_16:
		Team[t] == 0 => Team_slack[t] == 0 ;
		Team[t] == 0 => Team_surplus[t] == 0 ;
		Team[t] == 1 => Team_slack[t] >= 0 ;
		Team[t] == 1 => Team_surplus[t] >= 0 ;
		Team_slack[t] >= 1 => Team_surplus[t] == 0 ;
		Team_surplus[t] >= 1 => Team_slack[t] == 0 ;
		Team[t] == 1 && Team_slack[t] == 0 => Team_surplus[t] >= 0 ;
		Team[t] == 1 && Team_surplus[t] == 0 => Team_slack[t] >= 0 ;
	}
 
	ct_17:
		forall (r in sorted_route_f_l_time, t in indTeams) Team[t] >= RouteTeamAssign[t][r.route] ;
	
	ct_18:
		forall(t in indTeams, r in sorted_route_f_l_time){
			if(Current_Team_Route_Ext[t][r.ind] == 1){
				RouteTeamAssign[t][r.route] == 1 => NumChange[t][r.route] == 0 ;
				RouteTeamAssign[t][r.route] == 0 => NumChange[t][r.route] == 1 ; 	
			}
			if(Current_Team_Route_Ext[t][r.ind] == 0){
				RouteTeamAssign[t][r.route] == 1 => NumChange[t][r.route] == 1 ;
				RouteTeamAssign[t][r.route] == 0 => NumChange[t][r.route] == 0 ;
			}
		}

	ct_19:
		forall(t in indTeams){
			sum(r in sorted_route_f_l_time) NumChange[t][r.route] >= 1 => TeamChange[t] == 1 ;
			sum(r in sorted_route_f_l_time) NumChange[t][r.route] == 0 => TeamChange[t] == 0 ;
		}
	
	ct_20:
		forall(t in indTeams, r in sorted_route_f_l_time){
			if(Current_Team_Route_Ext[t][r.ind] == 1){
				NumChange[t][r.route] == 1 => RouteElimination[t][r.route] == 1;
				NumChange[t][r.route] == 0 => RouteElimination[t][r.route] == 0;
			}
			if(Current_Team_Route_Ext[t][r.ind] == 0){
				NumChange[t][r.route] == 1 => RouteAddition[t][r.route] == 1;
				NumChange[t][r.route] == 0 => RouteAddition[t][r.route] == 0;
			}
 			RouteElimination[t][r.route] + RouteAddition[t][r.route] <= 1 ;
 		}			
	
	if(OW_1 == 0){
		ct_21:
			sum(t in indTeams, r in sorted_route_f_l_time) NumChange[t][r.route] <= AllowedRouteTeamChanges ;
	}
	
	if(OW_1 == 1){
		ct_22:
			sum(t in indTeams) TeamChange[t] <= AllowedTeamChanges;	
	}
 
	if(OW_2 == 1){
		ct_23:
			forall(t_c in current_team_index) Team[t_c] == 1 ;	
	}
	
	if(OW_3 == 1){
		c_24:
			forall(t_p in FixedAssignments, t in indTeams : t == t_p.team_ind, r in sorted_route_f_l_time : r.route == t_p.route_number) 
				RouteTeamAssign[t][r.route] == 1;
			
			forall(t_p in FixedAssignments, t in indTeams : t != t_p.team_ind, r in sorted_route_f_l_time : r.route == t_p.route_number) 
				RouteTeamAssign[t][r.route] == 0;
	}
	
}		

/*********************************************** Post Process ************************************************/
tuple dot_dummy{
	int option;
	int team;
	int dummy;
	int dummy_start_time;
	int dummy_end_time;
}

{dot_dummy} DoT_Dummy;

execute{
	for(var i in DummyTeamAssignment){
		for(var j in WeekDay_DoTDummy){
			if(i.dummy == j.original_ind){
				DoT_Dummy.add(i.sol_num, i.team, i.dummy, j.dummy_start, j.dummy_end);
			}		
		}
		for(var k in WeekEnd_DoTDummy){
			if(i.dummy == k.original_ind){
				DoT_Dummy.add(i.sol_num, i.team, i.dummy, k.dummy_start, k.dummy_end);
			}		
		}	
	}
}

tuple TeamLeg {
	int option;
	float obj_value;
	float obj_value_milage_slack;
	float obj_value_milage_surplus;
	float obj_value_delta;
	float obj_value_total_teams;
	float obj_team_change;
	int team;
	int leg;
	int route;
	string r_d;
}

{TeamLeg} Team_Leg;
{TeamLeg} Team_Leg_Sorted;
int temp_leg[indTeams];

execute{
	for(var i in Sol_Summary){
		for(var t = 1 ; t <= MaxTeam ; t++){
			temp_leg[t] = 0 ;		
		}
		for(var k in DoT_Dummy){
			if(i.sol_num == k.option){
				temp_leg[k.team]++ ;
				Team_Leg.add(i.sol_num, Opl.ceil(i.sol_obj), Opl.ceil(i.mile_slack[k.team]), Opl.ceil(i.mile_surplus[k.team]), i.team_route_changes
					, i.total_teams, i.team_changes, k.team, temp_leg[k.team], k.dummy, "DoT_Dummy");
			}
		}		
		for(var j in RouteTeamAssignment){
			if(i.sol_num == j.sol_num){
				temp_leg[j.team]++;				
				Team_Leg.add(i.sol_num, Opl.ceil(i.sol_obj), Opl.ceil(i.mile_slack[j.team]), Opl.ceil(i.mile_surplus[j.team]), i.team_route_changes
					, i.total_teams, i.team_changes, j.team, temp_leg[j.team], j.route, "Route");
				writeln(" Option =   ", i.sol_num, " Slack =   ", Opl.ceil(i.mile_slack[j.team]), " Surplus =   ", Opl.ceil(i.mile_surplus[j.team])
					, " Changes =   ", i.team_route_changes, " Team =   ", j.team, " Leg =   ", temp_leg[j.team], " Route =   ", j.route);
 			}			
		}	
	}
}

tuple legs_f_tow{
	int option;
	float obj_value;
	float obj_value_milage_slack;
	float obj_value_milage_surplus;
	float obj_value_delta;
	float obj_value_total_teams;
	float obj_team_change;
	int team;
	int leg;
	int route;
	int F_ToW;
	string r_d;
}

{legs_f_tow} Legs_FirstArc_TOW;

execute{
	for(var i in Team_Leg){
		if(i.r_d == "Route"){
			for(var j in sorted_route_f_l_time){
				if(i.route == j.route){
					Legs_FirstArc_TOW.add(i.option, i.obj_value, i.obj_value_milage_slack, i.obj_value_milage_surplus, i.obj_value_delta
						, i.obj_value_total_teams, i.obj_team_change, i.team, i.leg, i.route, j.route_dispatch_ToW, "Route");
				}
			}
		}
		if(i.r_d == "DoT_Dummy"){
			for(var k in DoT_Dummy){
				if(i.route == k.dummy){
					Legs_FirstArc_TOW.add(i.option, i.obj_value, i.obj_value_milage_slack, i.obj_value_milage_surplus, i.obj_value_delta
						, i.obj_value_total_teams, i.obj_team_change, i.team, i.leg, i.route, k.dummy_start_time, "DoT_Dummy");
				}		
			}	
		}
	
	}
	
}

/******************************* Sorting Solutions *****************************/
sorted {int} sol_index = {o | <o, o_v, m_s, m_u, o_d, o_tt, o_tc, t, l, r, r_t, r_d> in Legs_FirstArc_TOW};
sorted {int} used_team_ind = {t | <o, o_v, m_s, m_u, o_d, o_tt, o_tc, t, l, r, r_t, r_d> in Legs_FirstArc_TOW};
int Option_Team_Leg[0..last(sol_index)][indTeams];
int leg_temp[0..last(sol_index)][indTeams][1..8];
int route_temp[0..last(sol_index)][indTeams][1..8];
int route_tow_temp[0..last(sol_index)][indTeams][1..8];
string r_d_temp[0..last(sol_index)][indTeams][1..8];

execute{
	for(var i in Team_Leg){
		for(var j in sol_index){
			if(i.option == j){
				for(var k in used_team_ind){
					if(i.team == k){
						Option_Team_Leg[j][k]++;
					}				
				}
			}		
		}	
	}

	var temp_leg = 0;
	var temp_route = 0;
	var temp_tow = 0;
	var temp_r_d = "";
	for(var y in Legs_FirstArc_TOW){
		for(var j in sol_index){
			if(y.option == j){
				for(var k in used_team_ind){
					if(y.team == k){
						leg_temp[j][k][y.leg] = y.leg;
						route_temp[j][k][y.leg] = y.route;
						route_tow_temp[j][k][y.leg] = y.F_ToW;
						r_d_temp[j][k][y.leg] = y.r_d;								
    				}
     			}
     		}     		
     	}
    }
    					
	for(var y in Legs_FirstArc_TOW){
		for(var j in sol_index){
			if(y.option == j){
				for(var k in used_team_ind){
					if(y.team == k){
						if(Option_Team_Leg[j][k] > 0){
							for(var t = 1 ; t <= Option_Team_Leg[j][k]-1 ; t++){
								for(var u = 1 ; u <= Option_Team_Leg[j][k]-t ; u++){
									if(route_tow_temp[j][k][u] >= route_tow_temp[j][k][u+1]){
										temp_tow = route_tow_temp[j][k][u];
										route_tow_temp[j][k][u] = route_tow_temp[j][k][u+1];
										route_tow_temp[j][k][u+1] = temp_tow;  
										temp_leg = leg_temp[j][k][u];
										leg_temp[j][k][u] = leg_temp[j][k][u+1];
										leg_temp[j][k][u+1] = temp_leg;
										temp_route = route_temp[j][k][u];
										route_temp[j][k][u] = route_temp[j][k][u+1];
										route_temp[j][k][u+1] = temp_route;
										temp_r_d = r_d_temp[j][k][u];
										r_d_temp[j][k][u] = r_d_temp[j][k][u+1];
										r_d_temp[j][k][u+1] = temp_r_d;
									}					
								}						
							}		
							for(var u = 1 ; u <= Option_Team_Leg[j][k] ; u++){
								Team_Leg_Sorted.add(j, y.obj_value, y.obj_value_milage_slack, y.obj_value_milage_surplus, y.obj_value_delta,
									y.obj_value_total_teams, y.obj_team_change, k, u, route_temp[j][k][u], r_d_temp[j][k][u]);						
							}
						}					
					}				
				}			
			}		
		}	
	}						
}

tuple team_leg_bin{
	int option;
	int team;
	int leg;
	int route;
	int leg_start;
	int leg_end;
	float miles;
	string r_d;
}

{team_leg_bin} Team_Leg_Assign;

execute{
	for(var i in Team_Leg_Sorted){
		if(i.r_d == "Route"){
			for(var j in sorted_route_f_l_time){
				if(i.route == j.route){
					Team_Leg_Assign.add(i.option, i.team, i.leg, i.route, j.route_dispatch_ToW, j.route_arrival_ToW, j.miles, j.state);				
				}			
			}		
		}
		if(i.r_d == "DoT_Dummy"){
			for(var k in WeekDay_DoTDummy){
				if(i.route == k.original_ind){
					Team_Leg_Assign.add(i.option, i.team, i.leg, i.route, k.dummy_start, k.dummy_end, 0 , "DoT_Dummy");			
				}	
			}
			for(var z in WeekEnd_DoTDummy){
				if(i.route == z.original_ind){
					Team_Leg_Assign.add(i.option, i.team, i.leg, i.route, z.dummy_start, z.dummy_end, 0 , "DoT_Dummy");			
				}		
			}
		}	
	}
}

int Change_Flag [0..last(sol_index)][indTeams][indTotalRoutes];

execute{
	for(var i in RouteTeamEliAdd){
		if(i.check == "Addition"){
			Change_Flag[i.sol_num][i.team][i.route] = 1;		
		}
	}
}

tuple Gantt{
	int option;
	float obj_value;
	float obj_team_route;
	float obj_team_change;
	float obj_num_team;
	float obj_slack;
	float obj_surplus;
	float cpu_sec;
	int Team_Num;
	string Team_Carrier;
	int team;
	int leg;
	int route;
	int arc_id;
	int arc_route;
	float arc_mile;
	string loc_from;
	string loc_to;
	string activity;
	string dispatch_DoW;
	int dispatch_ToD;
	int dispatch_ToW;
	string arrival_DoW;
	int arrival_ToD;
	int arrival_ToW;
	string release_DoW;
	int release_ToD;
	int release_ToW;
	int TeamNumOldOrg;
	string CarrierOldOrg;
	int Change_Flag;	
}

{Gantt} Gantt_Solution;
int NumAvaSol[0..SolutionPoolCapacity-1];
int TotalAvaSol;

execute{
	for(var i in Team_Leg_Sorted){
		if(i.r_d == "Route"){	
			for(var j in Route_Arc_ToW){
				if(i.route == j.route_number){
					Gantt_Solution.add(i.option, i.obj_value, i.obj_value_delta, i.obj_team_change, i.obj_value_total_teams, i.obj_value_milage_slack
						, i.obj_value_milage_surplus, cplex.getCplexTime(), Team_Att_Num[i.team], Team_Att_Carr[i.team], i.team, i.leg, i.route, j.arc_id
						, j.arc_route, j.miles, j.from_loc, j.to_loc, "Driving", j.dispatch_DoW, j.dispatch_ToD, j.dispatch_ToW, j.arrival_DoW, j.arrival_ToD
						, j.arrival_ToW, j.release_DoW, j.release_ToD, j.release_ToW, j.TeamNumOldOrg, j.CarrierOldOrg, Change_Flag[i.option][i.team][i.route]);			
				}
			}
 		}			
		if(i.r_d == "DoT_Dummy"){
			for(var k in WeekDay_DoTDummy){
				if(k.original_ind == i.route){
					Gantt_Solution.add(i.option, i.obj_value, i.obj_value_delta, i.obj_team_change, i.obj_value_total_teams, i.obj_value_milage_slack
						, i.obj_value_milage_surplus, cplex.getCplexTime(), Team_Att_Num[i.team], Team_Att_Carr[i.team], i.team, i.leg, 0000, 0, 0, 0
						, "DoT", "DoT", "DoT Rest", "DoT", 000, k.dummy_start, "DoT", 000, 000, "DoT", 000, k.dummy_end, 0, "DoT", 0);			
				}			
			}
			for(var k in WeekEnd_DoTDummy){
				if(k.original_ind == i.route){
					Gantt_Solution.add(i.option, i.obj_value, i.obj_value_delta, i.obj_team_change, i.obj_value_total_teams, i.obj_value_milage_slack
						, i.obj_value_milage_surplus, cplex.getCplexTime(), Team_Att_Num[i.team], Team_Att_Carr[i.team], i.team, i.leg, 0000, 0, 0, 0
						, "DoT", "DoT", "DoT Rest", "DoT", 000, k.dummy_start, "DoT", 000, 000, "DoT", 000, k.dummy_end, 0, "DoT", 0);			
				}			
			}
				
		}
	
	}
	for(var i in Gantt_Solution){
		for(var j = 0 ; j <= SolutionPoolCapacity-1 ; j++){
			if(i.option == j){
				NumAvaSol[j] = 1;
			}
		}
	}
	for(var j = 0 ; j <= SolutionPoolCapacity-1 ; j++){
		if(NumAvaSol[j] == 1){
			TotalAvaSol = TotalAvaSol + 1;				
		}
	}
}

{Gantt} Gantt_Solution_Sorted;
float temp_objval[1..TotalAvaSol];
int temp_option[1..TotalAvaSol];
float CPU_Time;

execute{
	 
	for(var i in Gantt_Solution){
		for(var o = 0 ; o < TotalAvaSol ; o++){
			if(o == i.option){
				temp_objval[o+1] = i.obj_value;
				temp_option[o+1] = i.option;			
			}
		}
	}
	var temp_val;
	var temp_opt_ord;
	for(var j = 1 ; j <= TotalAvaSol-1 ; j++){
		for(var k = 1 ; k <= TotalAvaSol-j ; k++){
			if(temp_objval[k] >= temp_objval[k+1]){
				temp_val = temp_objval[k];
				temp_objval[k] = temp_objval[k+1];
				temp_objval[k+1] = temp_val;
				temp_opt_ord = temp_option[k];
				temp_option[k] = temp_option[k+1];
				temp_option[k+1] = temp_opt_ord;
			}
		}
	}
	
	CPU_Time = cplex.getCplexTime();
	writeln (" CPU Time = ", CPU_Time) ;
	for(var z = 1 ; z <= TotalAvaSol ; z++){
		for(var x in Gantt_Solution){
			if(temp_option[z] == x.option){
				Gantt_Solution_Sorted.add(z, x.obj_value, x.obj_team_route, x.obj_team_change, x.obj_num_team, x.obj_slack, x.obj_surplus
					, CPU_Time, x.Team_Num, x.Team_Carrier, x.team, x.leg, x.route, x.arc_id, x.arc_route, x.arc_mile, x.loc_from, x.loc_to
					, x.activity, x.dispatch_DoW, x.dispatch_ToD, x.dispatch_ToW, x.arrival_DoW, x.arrival_ToD, x.arrival_ToW
					, x.release_DoW, x.release_ToD, x.release_ToW, x.TeamNumOldOrg, x.CarrierOldOrg, x.Change_Flag);			
			}	
		}	
	}
	 
}


