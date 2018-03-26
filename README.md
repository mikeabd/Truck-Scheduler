# Truck-Scheduler

This code has been developed to schedule Long Haul trucks of a leading pharmaceutical distritbution comapny, Cardinal Health Inc (Fortune 20). This code alont with a fully integrated UI went on production early 2016 and it is scheduling all the weekly trucks (140+ routes) and 7 days of the week at CAH to date.
Optimization constraints and parameters are explained in details within the body of the .mod model. The production code is slightly different as it is interacting with the UI with reading and writing parameters and solutions on a DB constantly.

Some of the important features of this solution are:
- Built out of scratch from problem formulation to the market research for existing software and tools to actual development and UI integration
- One of the only tools available in market that can take Department of Transportation constraints, existing Route configuration for each driver, acounts for Multi-Stop vs Single-Stop routes and provides optimal as well as sub-optimal solutions for easiness of execution (sometimes, decision makers are willing to sacrify optimality, most cheapest solution, to a slightly less optimal solution for easiness of route execution)
- The UI is fully integrated with a routing DB which is Geo coded and developed as a side project of this
- This solution reduced the (re)routing lead time at CAH from 3 weeks to 30-120 mins and a distict financial impact as well as risk reduction
- Lot's of soft parameters were provided to user to run various what-if scenarios making this tool as a custom-built solution according to the business needs rather than off the shelf expensive solutions

I have recieved my former employers permission to share the source code since its development in 2016.
