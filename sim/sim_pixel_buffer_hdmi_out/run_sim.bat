@echo off
rem Set the path to the Vivado executable
set vivado_path="C:\Xilinx\Vivado\2021.2\bin\vivado.bat"

rem Set TCL scripts to be called
set crete_sim_tcl=-source create_sim_prj.tcl
set run_sim_tcl=-source run_sim.tcl

rem Set the path to the simulation project directory
set folder=prj

rem Launch Vivado in batch mode to create the simulation project
rem Then, Launch Vivado in GUI mode to run the simulation
%vivado_path% -mode batch %crete_sim_tcl% && %vivado_path% -mode gui %folder%\prj.xpr %run_sim_tcl%

