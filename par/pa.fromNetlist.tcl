
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name gandarw -dir "C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par/planAhead_run_4" -part xc5vsx95tff1136-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par/gbase_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par} {../ipcore} {../submodules/data_out_manager/ipcore} {../submodules/arwen_prog/ipcore} }
add_files [list {../ipcore/the_spy_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../submodules/data_out_manager/ipcore/data_out_main_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../submodules/data_out_manager/ipcore/to_slink_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../submodules/arwen_prog/ipcore/arwen_prog_ila.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../submodules/arwen_prog/ipcore/binfile_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../submodules/arwen_prog/ipcore/tranceiver_ila.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/gbase.ucf" [current_fileset -constrset]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/amc0.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/gbase.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/gbase_prog.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/ocxo.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/omc1.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/ucf/slink.ucf}] -fileset [get_property constrset [current_run]]
link_design
