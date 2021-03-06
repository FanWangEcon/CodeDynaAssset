%% For Inf Tabulate Value and Policy Iteration Results, Store to Mat, Graph Results
% *back to <https://fanwangecon.github.io Fan>'s
% <https://fanwangecon.github.io/CodeDynaAsset/ Dynamic Assets Repository>
% Table of Content.*

%%
function [result_map] = ff_az_fibs_vf_post(varargin)
%% FF_AZ_FIBS_VF_POST post formal informal results
% In addition to regular post results
%
% @param param_map container parameter container
%
% @param support_map container support container
%
% @param armt_map container container with states, choices and shocks
% grids that are inputs for grid based solution algorithm
%
% @param func_map container container with function handles for
% consumption cash-on-hand etc.
%
% @param result_map container contains policy function matrix, value
% function matrix, iteration results
%
% @return result_map container add coh consumption and other matrixes to
% result_map also add table versions of val pol and iter matries
%
% @example
%
%    bl_input_override = true;
%    result_map = containers.Map('KeyType','char', 'ValueType','any');
%    result_map('mt_val') = mt_val;
%    result_map('mt_pol_a') = mt_pol_a;
%    result_map('ar_val_diff_norm') = ar_val_diff_norm(1:it_iter_last);
%    result_map('ar_pol_diff_norm') = ar_pol_diff_norm(1:it_iter_last);
%    result_map('mt_pol_perc_change') = mt_pol_perc_change(1:it_iter_last, :);
%    result_map = ff_az_vf_post(param_map, support_map, armt_map, func_map, result_map, bl_input_override);
%
% @include
%
% * <https://fanwangecon.github.io/CodeDynaAsset/m_az/solvepost/html/ff_az_vf_post_graph.html ff_az_vf_post_graph>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_az/paramfunc/html/ffs_az_set_default_param.html ffs_az_set_default_param>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_az/paramfunc/html/ffs_az_get_funcgrid.html ffs_az_get_funcgrid>
%

%% Default

if (~isempty(varargin))
    
    % if invoked from outside overrid fully
    [param_map, support_map, armt_map, func_map, result_map] = varargin{:};
        
else
    
    clear all;
    close all;
    
    % 1. internal invoke for testing
    it_param_set = 4;
    bl_input_override = true;
    
    % 2. Get Parameters
    [param_map, support_map] = ffs_abzr_fibs_set_default_param(it_param_set);
    [armt_map, func_map] = ffs_abzr_fibs_get_funcgrid(param_map, support_map, bl_input_override); % 1 for override
    
    % 3. Get Arrays and Functions
    params_group = values(param_map, {'it_a_n', 'it_z_n'});
    [it_a_n, it_z_n] = params_group{:};    
    params_group = values(armt_map, {'ar_a'});
    [ar_a] = params_group{:};
    params_group = values(armt_map, {'ar_z_r_infbr_mesh_wage', 'ar_z_wage_mesh_r_infbr'});
    [ar_z_r_inf_mesh_wage, ar_z_wage_mesh_r_inf] = params_group{:};    
    params_group = values(func_map, {'f_util_standin', 'f_cons_coh_fbis', 'f_cons_coh_save', 'f_coh'});
    [f_util_standin, f_cons_coh_fbis, f_cons_coh_save, f_coh] = params_group{:};
    
    % 4. Value Default
    mt_val = f_util_standin(ar_z_r_inf_mesh_wage, ar_a');
    
    % 5. default optimal asset choices (overall, interesint + principle from
    % different formal and informal sources following how model is solved)
    mt_pol_a = zeros(size(mt_val)) + ...
        ar_a'*(cumsum(sort(ar_z_r_inf_mesh_wage))/sum(ar_z_r_inf_mesh_wage)*0.4 + 0.4);
    
    % 6. Default COH
    mt_coh = f_coh(ar_z_r_inf_mesh_wage, ar_a');
    
    % 7. Set Default Consumption
    mt_pol_a_pos_idx = (mt_pol_a > 0);
    mt_pol_cons = zeros(size(mt_pol_a));
    mt_pol_cons(mt_pol_a_pos_idx) = f_cons_coh_save(mt_coh(mt_pol_a_pos_idx), mt_pol_a(mt_pol_a_pos_idx));
    mt_pol_cons(~mt_pol_a_pos_idx) = f_cons_coh_fbis(mt_coh(~mt_pol_a_pos_idx), mt_pol_a(~mt_pol_a_pos_idx));
    
    % 8. Find Formal Informal Choices given Fake Data
    mt_pol_b_bridge = zeros(it_a_n,it_z_n);
    mt_pol_inf_borr_nobridge = zeros(it_a_n,it_z_n);
    mt_pol_for_borr = zeros(it_a_n,it_z_n);
    mt_pol_for_save = zeros(it_a_n,it_z_n);
    
    % 9. Solve for formal and informal combinations given the overall fake
    % choices.
    for it_z_i = 1:it_z_n
        for it_a_j = 1:it_a_n

            fl_z_r_borr = ar_z_r_inf_mesh_wage(it_z_i);
            fl_z_wage = ar_z_wage_mesh_r_inf(it_z_i);
            param_map('fl_r_inf') = fl_z_r_borr;
            
            fl_a = ar_a(it_a_j);
            fl_coh = f_coh(fl_z_wage, fl_a);
            fl_a_opti = mt_pol_a(it_a_j, it_z_i);
            
            % call formal and informal function.
            [~, fl_opti_b_bridge, fl_opti_inf_borr_nobridge, fl_opti_for_borr, fl_opti_for_save] = ...
                ffs_fibs_min_c_cost_bridge(fl_a_opti, fl_coh, ...
                param_map, support_map, armt_map, func_map, bl_input_override);
            
            % store savings and borrowing formal and inf optimal choices
            mt_pol_b_bridge(it_a_j,it_z_i) = fl_opti_b_bridge;
            mt_pol_inf_borr_nobridge(it_a_j,it_z_i) = fl_opti_inf_borr_nobridge;
            mt_pol_for_borr(it_a_j,it_z_i) = fl_opti_for_borr;
            mt_pol_for_save(it_a_j,it_z_i) = fl_opti_for_save;
            
        end
    end
    
    % 10. Set Results Map
    result_map = containers.Map('KeyType','char', 'ValueType','any');
    result_map('mt_val') = mt_val;
    result_map('cl_mt_pol_a') = {mt_pol_a, zeros(1)};
    result_map('cl_mt_coh') = {mt_coh, zeros(1)};
    
    result_map('cl_mt_pol_c') = {mt_pol_cons, zeros(1)};
    result_map('cl_mt_pol_b_bridge') = {mt_pol_b_bridge, zeros(1)};
    result_map('cl_mt_pol_inf_borr_nobridge') = {mt_pol_inf_borr_nobridge, zeros(1)};
    result_map('cl_mt_pol_for_borr') = {mt_pol_for_borr, zeros(1)};
    result_map('cl_mt_pol_for_save') = {mt_pol_for_save, zeros(1)};
    
    % Input over-ride
    bl_input_override = true;
    result_map = ffs_fibs_identify_discrete(result_map, bl_input_override);
    
    % Control which results to graph
    support_map('bl_graph_forinf_discrete') = true;
    support_map('bl_graph_forinf_pol_lvl') = true;
    support_map('bl_graph_forinf_pol_pct') = true;
    
    support_map('bl_graph') = true;
    
end

%% Parse Parameter

% Model Name
params_group = values(param_map, {'st_model'});
[st_model] = params_group{:};

% armt_map standards
if (ismember(st_model, ["ipwkbzr_fibs", "abzr_fibs"]))
    params_group = values(param_map, {'fl_z_r_infbr_n'});
    [fl_z_r_borr_n] = params_group{:};
    if (ismember(st_model, ["ipwkbzr_fibs"]))
        params_group = values(armt_map, {'ar_z_r_infbr_mesh_wage_w1r2', 'ar_z_wage_mesh_r_infbr_w1r2'});
    elseif (ismember(st_model, ["abzr_fibs"]))
        params_group = values(armt_map, {'ar_z_r_infbr_mesh_wage', 'ar_z_wage_mesh_r_infbr'});
    end
    [ar_z_r_inf_mesh_wage, ar_z_wage_mesh_r_inf] = params_group{:};   
else
    fl_z_r_borr_n = 1;
    params_group = values(armt_map, {'ar_z'});
    [ar_z_wage_mesh_r_inf] = params_group{:};
end


% result_map standards
params_group = values(result_map, {'cl_mt_pol_a'});
[cl_mt_pol_a] = params_group{:};
[mt_pol_a] = deal(cl_mt_pol_a{1});

% result_map continuous formal informal choices
params_group = values(result_map, {'cl_mt_pol_b_bridge', 'cl_mt_pol_inf_borr_nobridge', ...
    'cl_mt_pol_for_borr', 'cl_mt_pol_for_save'});
[cl_mt_pol_b_bridge, cl_mt_pol_inf_borr_nobridge, cl_mt_pol_for_borr, cl_mt_pol_for_save] = params_group{:};
[mt_pol_b_bridge, mt_pol_inf_borr_nobridge, mt_pol_for_borr, mt_pol_for_save] = ...
    deal(cl_mt_pol_b_bridge{1}, cl_mt_pol_inf_borr_nobridge{1}, cl_mt_pol_for_borr{1}, cl_mt_pol_for_save{1});

% support_map
params_group = values(support_map, {'bl_display_final', 'it_display_final_rowmax', 'it_display_final_colmax'});
[bl_display_final, it_display_final_rowmax, it_display_final_colmax] = params_group{:};
params_group = values(support_map, {'bl_graph', 'bl_graph_onebyones'});
[bl_graph] = params_group{:};
params_group = values(support_map, {'bl_mat', 'st_mat_path', 'st_mat_prefix', 'st_mat_name_main', 'st_mat_suffix'});
[bl_mat, st_mat_path, st_mat_prefix, st_mat_name_main, st_mat_suffix] = params_group{:};

%% Get Size of Endogenous and Exogenous State

it_endostates_n = size(mt_pol_a, 1);
it_exostates_n = size(mt_pol_a, 2);

%% Generate Consumption and Income Matrix

if (~isKey(result_map, 'cl_mt_pol_c'))
    params_group = values(armt_map, {'ar_a', 'ar_z'});
    [ar_a, ar_z_r_inf_mesh_wage] = params_group{:};    
    f_cons = func_map('f_cons');
    mt_cons = f_cons(ar_z_r_inf_mesh_wage, ar_a', mt_pol_a);
    result_map('cl_mt_pol_c') = {mt_cons, zeros(1)};
end
if (~isKey(result_map, 'cl_mt_coh'))
    params_group = values(armt_map, {'ar_a', 'ar_z'});
    [ar_a, ar_z_r_inf_mesh_wage] = params_group{:};    
    f_coh = func_map('f_coh');
    mt_coh = f_coh(ar_z_r_inf_mesh_wage, ar_a');
    result_map('cl_mt_coh') = {mt_coh, zeros(1)};
else
    params_group = values(result_map, {'cl_mt_coh'});
    [cl_mt_coh] = params_group{:};
    [mt_coh] = deal(cl_mt_coh{1});
end

%% Save Mat

if (bl_mat)
    mkdir(support_map('st_mat_path'));
    st_file_name = [st_mat_prefix st_mat_name_main st_mat_suffix];
    save(strcat(st_mat_path, st_file_name));
end

%% Generate and Save Graphs

if (bl_graph)
    bl_input_override = true;
    ff_az_fibs_vf_post_graph(param_map, support_map, armt_map, func_map, result_map, bl_input_override);
end

%% Display Val Pol Iter Table

if (bl_display_final)
    
    % Display Values by States
    % at most display 11 columns of shocks
    % at most display 50 rows for states
    % display first and last
    if (it_endostates_n >= it_display_final_rowmax)
        ar_it_rows = (1:1:round(it_display_final_rowmax/2));
        ar_it_rows = [ar_it_rows ((it_endostates_n)-round(it_display_final_rowmax/2)+1):1:(it_endostates_n)];
    else
        ar_it_rows = 1:1:it_endostates_n;
    end
    ar_it_rows = unique(ar_it_rows);
    
    if (it_exostates_n >= it_display_final_colmax)
        ar_it_cols = (1:1:round(it_display_final_colmax/2));
        ar_it_cols = [ar_it_cols ((it_exostates_n)-round(it_display_final_colmax/2)+1):1:(it_exostates_n)];
    else
        ar_it_cols = 1:1:it_exostates_n;
    end
    ar_it_cols = unique(ar_it_cols);
    
    mt_pol_b_bridge_print = mt_pol_b_bridge(ar_it_rows, ar_it_cols);
    mt_pol_inf_borr_nobridge_print = mt_pol_inf_borr_nobridge(ar_it_rows, ar_it_cols);
    mt_pol_for_borr_print = mt_pol_for_borr(ar_it_rows, ar_it_cols);
    mt_pol_for_save_print = mt_pol_for_save(ar_it_rows, ar_it_cols);
    
    % Column Z Names
    if (fl_z_r_borr_n == 1)
        ar_st_col_zs = matlab.lang.makeValidName(strcat('z', string(ar_it_cols), '=', string(ar_z_wage_mesh_r_inf(ar_it_cols))));
    else
        ar_st_col_zs = matlab.lang.makeValidName(strcat('zi', string(ar_it_cols), ...
                                                        ':zr=', string(ar_z_r_inf_mesh_wage(ar_it_cols)), ...
                                                        ';zw=', string(ar_z_wage_mesh_r_inf(ar_it_cols))));                          
    end
    
    % Display Optimal Values
    tb_mt_pol_b_bridge_print = array2table(mt_pol_b_bridge_print);
    tb_mt_pol_b_bridge_print.Properties.RowNames = strcat('coh', string(ar_it_rows), '=', string(mt_coh(ar_it_rows)));
    tb_mt_pol_b_bridge_print.Properties.VariableNames = ar_st_col_zs;
    disp('mt_pol_b_bridge_print: bridge loans');
    disp(tb_mt_pol_b_bridge_print);
    
    % Display Optimal Values
    tb_mt_pol_inf_borr_nobridge_print = array2table(mt_pol_inf_borr_nobridge_print);
    tb_mt_pol_inf_borr_nobridge_print.Properties.RowNames = strcat('coh', string(ar_it_rows), '=', string(mt_coh(ar_it_rows)));
    tb_mt_pol_inf_borr_nobridge_print.Properties.VariableNames = ar_st_col_zs;
    disp('mt_pol_inf_borr_nobridge_print: Informal loans that is not bridge loan');
    disp(tb_mt_pol_inf_borr_nobridge_print);
    
    % Display Optimal Values
    tb_mt_pol_for_borr_print = array2table(mt_pol_for_borr_print);
    tb_mt_pol_for_borr_print.Properties.RowNames = strcat('coh', string(ar_it_rows), '=', string(mt_coh(ar_it_rows)));
    tb_mt_pol_for_borr_print.Properties.VariableNames = ar_st_col_zs;
    disp('mt_pol_for_borr_print: formal borrowing');
    disp(tb_mt_pol_for_borr_print);
    
    % Display Optimal Values
    tb_mt_pol_for_save_print = array2table(mt_pol_for_save_print);
    tb_mt_pol_for_save_print.Properties.RowNames = strcat('coh', string(ar_it_rows), '=', string(mt_coh(ar_it_rows)));
    tb_mt_pol_for_save_print.Properties.VariableNames = ar_st_col_zs;
    disp('mt_pol_for_save_print: formal savings');
    disp(tb_mt_pol_for_save_print);    
    
end

end
