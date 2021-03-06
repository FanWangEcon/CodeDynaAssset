%% Generate States, Choices and Shocks Grids and Get Functions (Interpolated + Percentage + Risky + Safe Asset + FIBS + RShock)
% *back to <https://fanwangecon.github.io Fan>'s
% <https://fanwangecon.github.io/CodeDynaAsset/ Dynamic Assets Repository>
% Table of Content.*

%%
function [armt_map, func_map] = ffs_ipwkbzr_fibs_get_funcgrid(varargin)
%% FFS_IPWKBZR_FIBS_GET_FUNCGRID get funcs, params, states choices shocks grids
% This file is based on
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_get_funcgrid.html
% ffs_ipwkbzr_get_funcgrid>, see that file for more comments and compare
% differences in graphs and tables to see how the inclusion of formal and
% informal choices that consider bridge loans impact choice sets.
%
% Also compare against
% <https://fanwangecon.github.io/CodeDynaAsset/m_fibs/m_abz_paramfunc/html/ffs_abz_fibs_get_funcgrid.html
% ffs_abz_fibs_get_funcgrid> where the results are also considering formal
% and informal choices etc in the context of *abz fibs*.
%
% In contrast to ff_ipwkbzr_evf.m, here, we need to deal with borrowing and
% savings formal and informal. These will change how the testing matrix is
% constructed. When bridge loan is allowed, we also need to construct the
% output matrixes differently. In ff_ipwkbzr_evf.m, the assumption is that
% coh today does not matter, so to find optimal k* choice, we only need to
% know the aggregate savings level. But now, we need to know the coh level
% as well.
%
% Below two reachable coh matrixes are constructed, one for when aggregate
% savings choice w >= 0, and another for when aggregate savings <= 0. Then
% they are stacked together. And we still have the same outputs as
% ff_ipwkbzr_evf.m. The difference is that while for savings where w >=0,
% each row are w levels for the output matrixes, but for w <=0, each row is
% for w level + coh percentage combinations.
%
% * _ar_w_level_: What are the feasible grid of w = k'+b', these are to be interpolated
% later, these are level grid, not percentage grid
% * _ar_w_level_: What are the percentage based choices points for k' and
% b' given each w. These are _ar_a_meshk_, _ar_k_mesha_. Note here these
% are principles, k + b' is the total aggregate savings in period t. b is
% be a combination of formal and informal choices, but our percentage point
% for b is the overall principle of all formal and informal choices
% * _mt_coh_wkb_full_ : These are the cash-on-hand levels reacheable given
% the choice percentages of k and b'. The problem here is more complicated
% than
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_get_funcgrid.html
% ffs_ipwkbzr_get_funcgrid> because here we can not get to coh tomorrow by
% multiplying principle by savings or borrowing interest rates, if
% borrowing, we have to optimize among formal and informal choices. That is
% computationally trivial because it's a static choice unrelated to the
% dynamic problem. The slightly more complicated thing is that we also have
% to consider percentages of b' that has to go to bridge loans due to
% negative cash-on-hand in period t. That makes the reachable cash-on-hand
% grid significantly larger than the grid in
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_get_funcgrid.html
% ffs_ipwkbzr_get_funcgrid>, we have to expand the grid by another
% percentage dimension--percentages of b' going to bridge--for negative
% levels of w=k'+b' overall choice.
%

%% Default
% Results identical to
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_get_funcgrid.html
% ffs_ipwkbzr_get_funcgrid> is obtained by running default with:
% st_param_which = 'ffs_ipwkbzr_get_funcgrid';
%

if (~isempty(varargin))
    
    % override when called from outside
    [param_map, support_map] = varargin{:};
    
else
    
    close all;
    % default internal run
    [param_map, support_map] = ffs_ipwkbzr_fibs_set_default_param();
    support_map('bl_graph_funcgrids') = true;
    support_map('bl_graph_funcgrids_detail') = true;
    support_map('bl_display_funcgrids') = true;

    st_param_which = 'default';

    param_map('fl_z_r_infbr_min') = 0.025;
    param_map('fl_z_r_infbr_max') = 0.95;
    param_map('fl_z_r_infbr_n') = 3;
    
    if (ismember(st_param_which, ['default', 'ffs_ipwkbzr_get_funcgrid']))

        % to be able to visually see choice grid points
        param_map('fl_b_bd') = -20; % borrow bound, = 0 if save only
        param_map('fl_default_aprime') = 0;
        param_map('bl_default') = 0; % if borrowing is default allowed

        param_map('fl_w_min') = param_map('fl_b_bd');
        param_map('it_w_perc_n') = 25;
        param_map('it_ak_perc_n') = 45;

        param_map('fl_w_interp_grid_gap') = 2;
        param_map('fl_coh_interp_grid_gap') = 2;

        % Note it_coh_bridge_perc is percentage NOT for BRIDGE
        if (strcmp(st_param_which, 'default'))

            param_map('it_coh_bridge_perc_n') = 3;
            param_map('bl_bridge') = true;

        elseif (strcmp(st_param_which, 'ffs_ipwkbzr_get_funcgrid'))

            % when bl_bridge = false, it_coh_bridge_perc_n = 1
            param_map('bl_bridge') = false;

        end

    elseif (strcmp(st_param_which, 'small'))

        param_map('bl_bridge') = true;
        
        % to be able to visually see choice grid points
        param_map('fl_b_bd') = -20; % borrow bound, = 0 if save only
        param_map('fl_default_aprime') = 0;
        param_map('bl_default') = false; % if borrowing is default allowed

        param_map('fl_w_min') = param_map('fl_b_bd');
        param_map('it_w_perc_n') = 7;
        param_map('it_ak_perc_n') = 7;
        param_map('it_coh_bridge_perc_n') = 3;

        param_map('fl_w_interp_grid_gap') = 2;
        param_map('fl_coh_interp_grid_gap') = 2;

    end

    param_map('it_z_n') = param_map('it_z_wage_n') * param_map('fl_z_r_infbr_n');

    default_maps = {param_map, support_map};

    % numvarargs is the number of varagin inputted
    [default_maps{1:length(varargin)}] = varargin{:};
    param_map = [param_map; default_maps{1}];
    support_map = [support_map; default_maps{2}];
end

%% Parse Parameters 1a

params_group = values(param_map, {'bl_bridge', 'fl_b_bd', 'fl_w_min', 'fl_w_max'});
[bl_bridge, fl_b_bd, fl_w_min, fl_w_max] = params_group{:};

params_group = values(param_map, {'fl_crra', 'fl_c_min'});
[fl_crra, fl_c_min] = params_group{:};

params_group = values(param_map, {'fl_Amean', 'fl_alpha', 'fl_delta'});
[fl_Amean, fl_alpha, fl_delta] = params_group{:};

params_group = values(param_map, {'bl_b_is_principle', 'fl_r_fbr', 'fl_r_fsv', 'fl_w'});
[bl_b_is_principle, fl_r_fbr, fl_r_fsv, fl_w] = params_group{:};

%% Parse Parameters 1b

params_group = values(param_map, {...
    'it_w_perc_n', 'it_ak_perc_n', 'it_coh_bridge_perc_n', ...
    'it_c_interp_grid_gap', 'fl_w_interp_grid_gap', 'fl_coh_interp_grid_gap'});
[it_w_perc_n, it_ak_perc_n, it_coh_bridge_perc_n, ...
    it_c_interp_grid_gap, fl_w_interp_grid_gap, fl_coh_interp_grid_gap] = params_group{:};

params_group = values(param_map, {'st_v_coh_z_interp_method'});
[st_v_coh_z_interp_method] = params_group{:};

%% Parse Parameters 2

% param_map shock income
params_group = values(param_map, {'it_z_wage_n', 'fl_z_wage_mu', 'fl_z_wage_rho', 'fl_z_wage_sig'});
[it_z_wage_n, fl_z_wage_mu, fl_z_wage_rho, fl_z_wage_sig] = params_group{:};

% param_map shock borrowing interest
params_group = values(param_map, {'st_z_r_infbr_drv_ele_type', 'st_z_r_infbr_drv_prb_type', 'fl_z_r_infbr_poiss_mean', ...
    'fl_z_r_infbr_max', 'fl_z_r_infbr_min', 'fl_z_r_infbr_n'});
[st_z_r_infbr_drv_ele_type, st_z_r_infbr_drv_prb_type, fl_z_r_infbr_poiss_mean, ...
    fl_z_r_infbr_max, fl_z_r_infbr_min, fl_z_r_infbr_n] = params_group{:};

% param_map formal menu
params_group = values(param_map, {'st_forbrblk_type', 'fl_forbrblk_brmost', 'fl_forbrblk_brleast', 'fl_forbrblk_gap'});
[st_forbrblk_type, fl_forbrblk_brmost, fl_forbrblk_brleast, fl_forbrblk_gap] = params_group{:};

% param_map shock income
params_group = values(param_map, {'it_z_n'});
[it_z_n] = params_group{:};

%% Parse Parameters 3

params_group = values(support_map, {'bl_display_minccost', 'bl_graph_funcgrids', 'bl_graph_funcgrids_detail', 'bl_display_funcgrids'});
[bl_display_minccost, bl_graph_funcgrids, bl_graph_funcgrids_detail, bl_display_funcgrids] = params_group{:};
params_group = values(support_map, {'it_display_summmat_rowmax', 'it_display_summmat_colmax'});
[it_display_summmat_rowmax, it_display_summmat_colmax] = params_group{:};

%% G1: Generate Asset and Choice Grid for 2nd stage Problem
% This generate triangular choice structure. Household choose total
% aggregate savings, and within that how much to put into risky capital and
% how much to put into safe assets, in percentages. See
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_fibs_set_default_param.html
% ffs_ipwkbzr_fibs_set_default_param> for details.
%
% @example
%
%    % For 2nd stage Grid
%    ar_w_level = [-2,0,2]
%    fl_b_bd = -4
%    ar_k_max = ar_w_level - fl_b_bd
%    ar_ak_perc = [0.001, 0.1,0.3,0.7,0.9, 0.999]
%    mt_k = (ar_k_max'*ar_ak_perc)'
%    mt_a = (ar_w_level - mt_k)
%

% percentage grid for 1st stage choice problem, level grid for 2nd stage
% solving optimal k given w and z.
ar_w_perc = linspace(0.001, 0.999, it_w_perc_n);
it_w_interp_n = (fl_w_max-fl_w_min)/(fl_w_interp_grid_gap);
ar_w_level_full = fft_array_add_zero(linspace(fl_w_min, fl_w_max, it_w_interp_n), true);
ar_w_level = ar_w_level_full;
it_w_interp_n = length(ar_w_level_full);

% max k given w, need to consider the possibility of borrowing.
ar_k_max = ar_w_level_full - fl_b_bd;

% k percentage choice grid
ar_ak_perc = linspace(0.001, 0.999, it_ak_perc_n);

% 2nd stage percentage choice matrixes
% (ar_k_max') is it_w_interp_n by 1, and (ar_ak_perc) is 1 by it_ak_perc_n
% mt_k is a it_w_interp_n by it_ak_perc_n matrix of choice points of k'
% conditional on w, each column is a different w, each row for each col a
% different k' value.
mt_k = (ar_k_max'*ar_ak_perc)';
mt_a = (ar_w_level_full - mt_k);

% can not have choice that are beyond feasible bound given the percentage
% structure here.
mt_bl_constrained = (mt_a < fl_b_bd);
if (sum(mt_bl_constrained) > 0 )
    error('at %s second stage choice points, percentage choice exceed bounds, can not happen',...
        num2str(sum(mt_bl_constrained)));
end

%% G2: Expand A and K Arrays further if bridge is allowed
% Crucially, when a fraction of overall borrowing/savings needs to go pay
% negative coh, that comes out of w, fraction of w = k' + b' that goes to
% this. NOT a fraction of the b' choice condition on w, which would change
% for the same w as w' changes. We are fixing bridge repay level for w.
%
% @example
%
%    clear all
%    % Same as above
%    ar_w_level = [-2,-1,-0.1]
%    fl_b_bd = -4
%    ar_k_max = ar_w_level - fl_b_bd
%    ar_ak_perc = [0.001, 0.1,0.3,0.7,0.9, 0.999]
%    mt_k = (ar_k_max'*ar_ak_perc)'
%    mt_a = (ar_w_level - mt_k)
%
%    % fraction of borrowing for bridge loan
%    ar_coh_bridge_perc = [0, 0.5, 0.999];
%
%    % Expand matrix to include coh percentage dimension
%    mt_k = repmat(mt_k, [1, length(ar_coh_bridge_perc)])
%    mt_a = repmat(mt_a, [1, length(ar_coh_bridge_perc)])
%
%    % bridge loan component of borrowing
%    ar_brdige_a = (ar_coh_bridge_perc'*ar_w_level)'
%    ar_brdige_a = ar_brdige_a(:)'
%
%    % borrowing choices excluding bridge loan
%    mt_a_nobridge = mt_a - ar_brdige_a
%

% 1. negative part of w
ar_bl_w_neg = (ar_w_level < 0);
ar_w_level_neg = ar_w_level(ar_bl_w_neg);

if (bl_bridge)

    % 1. select mt_k and mt_a where w_level <= 0
    mt_a_wneg_cols = mt_a(:, ar_bl_w_neg);
    mt_k_wneg_cols = mt_k(:, ar_bl_w_neg);

    % 2. fraction of borrowing NOT for bridge loan
    % 0 means 100 percent of w will go to bridge, 1 mean nothing for bridge
    ar_coh_bridge_perc = linspace(0, 1.0, it_coh_bridge_perc_n);

    % 3. Expand matrix to include coh percentage dimension
    mt_k_wneg_cols = repmat(mt_k_wneg_cols, [1, length(ar_coh_bridge_perc)]);
    mt_a_wneg_cols = repmat(mt_a_wneg_cols, [1, length(ar_coh_bridge_perc)]);

    % 4. bridge loan component of borrowing
    ar_brdige_a = ((1-ar_coh_bridge_perc)'*ar_w_level_neg)';
    ar_brdige_a = ar_brdige_a(:)';

    % 5. borrowing choices excluding bridge loan
    mt_a_wneg_nobridge = mt_a_wneg_cols - ar_brdige_a;

    % 6. Matrix combine, negative than positive
    mt_a_wpos_cols = mt_a(:, ~ar_bl_w_neg);
    mt_k_wpos_cols = mt_k(:, ~ar_bl_w_neg);
    mt_a_nobridge = [mt_a_wneg_nobridge  mt_a_wpos_cols];
    mt_k = [mt_k_wneg_cols                mt_k_wpos_cols];

    % 7. Expand Bridge Choices to have the same size as mt_a
    mt_bridge_a= zeros(size(mt_a_nobridge));
    mt_bridge_a(:, 1:1:size(mt_a_wneg_nobridge,2)) = zeros(size(mt_a_wneg_nobridge)) + ar_brdige_a;

    % 8. Overall borrowing and savings choices
    mt_a = mt_a_nobridge + mt_bridge_a;

    % 9. Update w
    ar_w_level_full = zeros(size(mt_a_nobridge(1,:)));
    ar_w_level_neg_rep = repmat(ar_w_level_neg, [1, length(ar_coh_bridge_perc)]);
    ar_w_level_full(1:1:size(mt_a_wneg_nobridge,2)) = ar_w_level_neg_rep;
    ar_w_level_full((size(mt_a_wneg_nobridge,2)+1):1:length(ar_w_level_full)) = ar_w_level(~ar_bl_w_neg);

    % 10. Pre-generate Interpolation matrix for negative w levels
    [mt_w_level_neg_mesh_coh_bridge_perc, mt_coh_bridge_perc_mesh_w_level_neg] = ...
        ndgrid(ar_w_level_neg, ar_coh_bridge_perc);

else

    % If bridge loans are not needed, do not need to do expansions
    % All zeros, no bridge
    mt_bridge_a = zeros(size(mt_a));
    mt_a_nobridge = mt_a;
    ar_coh_bridge_perc = [1];

    [mt_w_level_neg_mesh_coh_bridge_perc, mt_coh_bridge_perc_mesh_w_level_neg] = ...
        ndgrid(ar_w_level_neg, ar_coh_bridge_perc);

end

%% G3: Flatten Choices to Arrays to be Combined with Shocks as Columns.
% For the arrays below, their dimensionality are all: N_neg*N^2 + N_pos*N
% number of rows. Where N is the percentage grid point for coh as well as
% k' choices: N = it_ak_perc_n = it_coh_bridge_perc_n; And N_neg + N_pos =
% numger of grid points for ar_w_level
%
% # *mt_a* includes aggregate/total borrowing and savings levels. b < 0 happens
% alot when w >= 0. The mt_a_nobridge
% # *mt_a_nobridge* includes all aggregate/total borrowing and savings
% whether w > 0 or w < 0, however, it subtracts away the borrowing that is
% for bridge loans when b < 0
% # *mt_bridge_a* is the bridge loan amount.
%

ar_a_meshk_full = mt_a(:);
ar_a_nobridge_meshk_full = mt_a_nobridge(:);
ar_k_mesha_full = mt_k(:);
ar_bridge_a_full = mt_bridge_a(:);

ar_a_meshk = ar_a_meshk_full;
ar_a_nobridge_meshk = ar_a_nobridge_meshk_full;
ar_k_mesha = ar_k_mesha_full;
ar_bridge_a = ar_bridge_a_full;

%% F1: Get Shock: Income Shock (ar1)

[~, mt_z_wage_trans, ar_z_wage_prob, ar_z_wage] = ffto_gen_tauchen_jhl(fl_z_wage_mu,fl_z_wage_rho,fl_z_wage_sig,it_z_wage_n);

%% F2: Get Shock: Interest Rate Shock (iid)

% get borrowing grid and probabilities
param_dsv_map = containers.Map('KeyType','char', 'ValueType','any');
param_dsv_map('st_drv_ele_type') = st_z_r_infbr_drv_ele_type;
param_dsv_map('st_drv_prb_type') = st_z_r_infbr_drv_prb_type;
param_dsv_map('fl_poiss_mean') = fl_z_r_infbr_poiss_mean;
param_dsv_map('fl_max') = fl_z_r_infbr_max;
param_dsv_map('fl_min') = fl_z_r_infbr_min;
param_dsv_map('fl_n') = fl_z_r_infbr_n;
[ar_z_r_infbr, ar_z_r_infbr_prob] = fft_gen_discrete_var(param_dsv_map, true);

% iid transition matrix
mt_z_r_infbr_prob_trans = repmat(ar_z_r_infbr_prob, [length(ar_z_r_infbr_prob), 1]);

%% F3: Get Shock: Mesh Shocks Together

% Kronecker product to get full transition matrix for the two shocks
mt_z_trans = kron(mt_z_r_infbr_prob_trans, mt_z_wage_trans);

% mesh the shock vectors
[mt_z_wage_mesh_r_infbr_w1r2, mt_z_r_infbr_mesh_wage_w1r2] = ndgrid(ar_z_wage, ar_z_r_infbr);
ar_z_r_infbr_mesh_wage_w1r2 = mt_z_r_infbr_mesh_wage_w1r2(:)';
ar_z_wage_mesh_r_infbr_w1r2 = mt_z_wage_mesh_r_infbr_w1r2(:)';

% mesh the shock vectors
[mt_z_r_infbr_mesh_wage_r1w2, mt_z_wage_mesh_r_infbr_r1w2] = ndgrid(ar_z_r_infbr, ar_z_wage);
ar_z_wage_mesh_r_infbr_r1w2 = mt_z_wage_mesh_r_infbr_r1w2(:)';
ar_z_r_infbr_mesh_wage_r1w2 = mt_z_r_infbr_mesh_wage_r1w2(:)';


if (bl_display_funcgrids)

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('Borrow R Shock: ar_z_r_infbr_mesh_wage_w1r2');
    disp('Prod/Wage Shock: ar_z_wage_mesh_r_infbr_w1r2');
    disp('show which shock is inner and which is outter');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

    tb_two_shocks = array2table([ar_z_r_infbr_mesh_wage_w1r2;...
                                 ar_z_wage_mesh_r_infbr_w1r2]');
    cl_col_names = ["Borrow R Shock (Meshed)", "Wage R Shock (Meshed)"];
    cl_row_names = strcat('zi=', string((1:it_z_n)));
    tb_two_shocks.Properties.VariableNames = matlab.lang.makeValidName(cl_col_names);
    tb_two_shocks.Properties.RowNames = matlab.lang.makeValidName(cl_row_names);

    it_row_display = it_z_wage_n*2;

    disp(size(tb_two_shocks));
    disp(head(tb_two_shocks, it_row_display));
    disp(tail(tb_two_shocks, it_row_display));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('Borrow R Shock: ar_z_wage_mesh_r_infbr_r1w2');
    disp('Prod/Wage Shock: ar_z_r_infbr_mesh_wage_r1w2');
    disp('show which shock is inner and which is outter');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

    tb_two_shocks = array2table([ar_z_wage_mesh_r_infbr_r1w2;...
                                 ar_z_r_infbr_mesh_wage_r1w2]');
    cl_col_names = ["Borrow R Shock (Meshed)", "Wage R Shock (Meshed)"];
    cl_row_names = strcat('zi=', string((1:length(ar_z_r_infbr_mesh_wage_r1w2))));
    tb_two_shocks.Properties.VariableNames = matlab.lang.makeValidName(cl_col_names);
    tb_two_shocks.Properties.RowNames = matlab.lang.makeValidName(cl_row_names);

    it_row_display = fl_z_r_infbr_n*2;

    disp(size(tb_two_shocks));
    disp(head(tb_two_shocks, it_row_display));
    disp(tail(tb_two_shocks, it_row_display));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('Borrow Rate Transition Matrix: mt_z_r_infbr_prob_trans');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    it_col_n_keep = 15;
    it_row_n_keep = 15;
    [it_row_n, it_col_n] = size(mt_z_r_infbr_prob_trans);
    [ar_it_cols, ar_it_rows] = fft_row_col_subset(it_col_n, it_col_n_keep, it_row_n, it_row_n_keep);
    cl_st_full_rowscols = cellstr([num2str(ar_z_r_infbr', 'r%3.2f')]);
    tb_z_r_infbr_prob_trans = array2table(round(mt_z_r_infbr_prob_trans(ar_it_rows, ar_it_cols), 6));
    cl_col_names = strcat('zi=', num2str(ar_it_cols'), ':', cl_st_full_rowscols(ar_it_cols));
    cl_row_names = strcat('zi=', num2str(ar_it_rows'), ':', cl_st_full_rowscols(ar_it_rows));
    tb_z_r_infbr_prob_trans.Properties.VariableNames = matlab.lang.makeValidName(cl_col_names);
    tb_z_r_infbr_prob_trans.Properties.RowNames = matlab.lang.makeValidName(cl_row_names);

    disp(size(tb_z_r_infbr_prob_trans));
    disp(tb_z_r_infbr_prob_trans);

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('Wage Prod Shock Transition Matrix: mt_z_r_infbr_prob_trans');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    it_col_n_keep = 15;
    it_row_n_keep = 15;
    [it_row_n, it_col_n] = size(mt_z_wage_trans);
    [ar_it_cols, ar_it_rows] = fft_row_col_subset(it_col_n, it_col_n_keep, it_row_n, it_row_n_keep);
    cl_st_full_rowscols = cellstr([num2str(ar_z_wage', 'w%3.2f')]);
    tb_z_wage_trans = array2table(round(mt_z_wage_trans(ar_it_rows, ar_it_cols),6));
    cl_col_names = strcat('zi=', num2str(ar_it_cols'), ':', cl_st_full_rowscols(ar_it_cols));
    cl_row_names = strcat('zi=', num2str(ar_it_rows'), ':', cl_st_full_rowscols(ar_it_rows));
    tb_z_wage_trans.Properties.VariableNames = matlab.lang.makeValidName(cl_col_names);
    tb_z_wage_trans.Properties.RowNames = matlab.lang.makeValidName(cl_row_names);

    disp(size(tb_z_wage_trans));
    disp(tb_z_wage_trans);

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('Full Transition Matrix: mt_z_trans');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    it_col_n_keep = it_z_wage_n*3;
    it_row_n_keep = it_z_wage_n*3;
    [it_row_n, it_col_n] = size(mt_z_trans);
    [ar_it_cols, ar_it_rows] = fft_row_col_subset(it_col_n, it_col_n_keep, it_row_n, it_row_n_keep);
    cl_st_full_rowscols = cellstr([num2str(ar_z_r_infbr_mesh_wage_w1r2', 'r%3.2f;'), ...
                                   num2str(ar_z_wage_mesh_r_infbr_w1r2', 'w%3.2f')]);
    tb_mt_z_trans = array2table(round(mt_z_trans(ar_it_rows, ar_it_cols),6));
    cl_col_names = strcat('i', num2str(ar_it_cols'), ':', cl_st_full_rowscols(ar_it_cols));
    cl_row_names = strcat('i', num2str(ar_it_rows'), ':', cl_st_full_rowscols(ar_it_rows));
    tb_mt_z_trans.Properties.VariableNames = matlab.lang.makeValidName(cl_col_names);
    tb_mt_z_trans.Properties.RowNames = matlab.lang.makeValidName(cl_row_names);

    disp(size(tb_mt_z_trans));
    disp(tb_mt_z_trans);

end

%% FIBS1: Get Equations

[f_util_log, f_util_crra, f_util_standin, f_util_standin_coh, f_prod, f_inc, f_coh, f_coh_fbis, f_coh_save, f_cons] = ...
    ffs_ipwkbzr_fibs_set_functions(fl_crra, fl_c_min, fl_b_bd, fl_Amean, fl_alpha, fl_delta, fl_w, fl_r_fbr, fl_r_fsv);

%% FIBS2: Get Formal Borrowing Blocks

[ar_forbrblk, ar_forbrblk_r] = ...
        ffs_for_br_block_gen(fl_r_fbr, st_forbrblk_type, fl_forbrblk_brmost, fl_forbrblk_brleast, fl_forbrblk_gap);

%% Find Formal and Informal Choices for Borrowing points
% Here we solve for the optimal formal and informal choices given b. Note
% that kind of like the static firm's maximization problem. Here the
% optimization problem is static, and can be done independently of the
% overall dynamic optimization problem.

% When borrowing index and array
% note index for negative is from _ar_a_meshk_full_, but value from
% _ar_a_nobridge_meshk_. Index from _ar_a_meshk_full_, which means at some
% of these points _ar_a_nobridge_meshk_ = 0. But need to use
% _ar_bl_ameshk_neg_idx_ because *f_coh_fbis* function below applies to all
% borrowing.
ar_bl_ameshk_neg_idx = (ar_a_meshk_full < 0);
ar_a_meshk_nobridge_aneg = ar_a_nobridge_meshk(ar_bl_ameshk_neg_idx);

% Given b, solve for optimal formal and informal choices.
bl_input_override = true;
[~, ar_inf_borr_nobridge_aneg, ar_for_infbr_aneg, ar_for_save_aneg] = ...
   ffs_fibs_min_c_cost(bl_b_is_principle, ar_z_r_infbr, fl_r_fsv, ...
                         ar_forbrblk_r, ar_forbrblk, ...
                         ar_a_meshk_nobridge_aneg, bl_display_minccost, bl_input_override);

%% FIBS3: Generate C cost Matrix when aggregate savings = k'+b' is negative
% *ar_coh_fbis_aneg*: the consumption cost to t+1 from borrowing in t given
% formal and informal joint choice optimization.
%
% Reachable cash-on-hand borrowing points: N_neg*N^2 rows
%
% Additionally, need to convert borrowing choices to consumption units next
% period. borrowing choices in percentage are in unit of last period
% borrowing, principles only, need to convert to interest rates plus
% principle which means considering which formal informal choice
% combination maximizes cash-on-hand for the same level of overall
% principles.
%
% Construct another percentage, which is, percentages of ar_a_meshk_full
% when w < 0. Percentage represents what fraction of the a debt is going
% towards bridge loan debts. Note that as long as w < 0, b < 0 must be the
% case as well. So for negative elements of w, there is a triple mesh: N
% points for A x N points for K x N points for Bridge.
%

ar_coh_fbis_aneg = f_coh_fbis(ar_z_r_infbr, ...
                                ar_for_infbr_aneg, ...
                                ar_inf_borr_nobridge_aneg + ar_bridge_a(ar_bl_ameshk_neg_idx), ...
                                ar_for_save_aneg);

%% FIBS3: Generate C cost Cash-on-Hand/State Matrix when aggregate savings is positive
% *ar_coh_save_apos*: the consumption gain to t+1 from savings in t

ar_a_meshk_apos = ar_a_meshk(~ar_bl_ameshk_neg_idx);
ar_coh_save_apos = f_coh_save(ar_a_meshk_apos);

%% COH1: Combine overall Reachable Cash-on-Hand Levels
% ROWS: N_neg*N^2 + N_pos*N rows total row count, and N_z shock column count.
% These are the cash-on-hand points reachable given percentage grid choice
% structure and the possibility of bridge loans.
% COLUMNS: determined by length(ar_z_r_infbr), each column a different
% informal borrowing interest rate.
%
% # mt_coh_wkb_full: this is the (P^k x I^w x M^r) by (M^z) matrix, where
% rows = it_w_interp_n*it_ak_perc_n*fl_z_r_infbr_n, and cols = it_z_wage_n.
%

mt_ameshk_tnext_with_r = zeros(length(ar_k_mesha), fl_z_r_infbr_n);
mt_ameshk_tnext_with_r(ar_bl_ameshk_neg_idx, :) = ar_coh_fbis_aneg;
mt_ameshk_tnext_with_r(~ar_bl_ameshk_neg_idx, :) = zeros(1, fl_z_r_infbr_n) + ar_coh_save_apos;

% # mt_ameshk_tnext_with_r: ((P^{k}_{a>=0} + P^{k}_{a<0} x P^{w frac bridge} ) x I^w ) by (M^r) matrix
% # mt_coh_wkb_full: ((P^{k}_{a>=0} + P^{k}_{a<0} x P^{w frac bridge} ) x I^w x M^r) by (M^z) matrix

mt_k_mesha_mesh_z_wage = ar_k_mesha + zeros(1, fl_z_r_infbr_n);
mt_coh_wkb_full = f_coh(ar_z_wage, mt_ameshk_tnext_with_r(:), mt_k_mesha_mesh_z_wage(:));

% Generate Aggregate Variables
ar_aplusk_mesh = ar_a_meshk_full + ar_k_mesha_full;

if (bl_display_funcgrids || bl_graph_funcgrids)
    
    % Generate Aggregate Variables
    mt_bwithrplusk_mesh = mt_ameshk_tnext_with_r + ar_k_mesha;

    % Genereate Table
    tab_ak_choices = array2table([mt_bwithrplusk_mesh, ar_aplusk_mesh, ...
                                  ar_k_mesha, mt_ameshk_tnext_with_r, ar_a_meshk, ar_a_nobridge_meshk, ar_bridge_a]);
    cl_col_names = [strcat('mt_bwthrplusk', string((1:length(ar_z_r_infbr)))), ...
                    'ar_aplusk_mesha', 'ar_k_mesha', ...
                    strcat('mt_a_wth_r_infbr', string((1:length(ar_z_r_infbr)))), ...
                    'ar_a_meshk', 'ar_a_nobridge_meshk', 'ar_bridge_a'];
    tab_ak_choices.Properties.VariableNames = cl_col_names;

    % Label Table Variables
    tab_ak_choices.Properties.VariableDescriptions{'ar_aplusk_mesha'} = ...
        '*ar_aplusk_mesha*:';
    tab_ak_choices.Properties.VariableDescriptions{'ar_k_mesha'} = ...
        '*ar_k_mesha*:';
    tab_ak_choices.Properties.VariableDescriptions{'ar_a_meshk'} = ...
        '*ar_a_meshk*:';
    tab_ak_choices.Properties.VariableDescriptions{'ar_a_nobridge_meshk'} = ...
        '*ar_aprime_nobridge*:';
    tab_ak_choices.Properties.VariableDescriptions{'ar_bridge_a'} = ...
        '*ar_bridge_a*:';

    cl_var_desc = tab_ak_choices.Properties.VariableDescriptions;
    for it_var_name = 1:length(cl_var_desc)
        disp(cl_var_desc{it_var_name});
    end

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('tab_ak_choices');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    it_rows_toshow = length(ar_w_level)*2;
    disp(size(tab_ak_choices));
    disp(head(array2table(tab_ak_choices), it_rows_toshow));
    disp(tail(array2table(tab_ak_choices), it_rows_toshow));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_coh_wkb_full');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_coh_wkb_full));
    disp(head(array2table(mt_coh_wkb_full), it_rows_toshow));
    disp(tail(array2table(mt_coh_wkb_full), it_rows_toshow));

end

%% COH2: Check if COH is within Borrowing Bounds
% some coh levels are below borrowing bound, can not borrow enough to pay
% debt

mt_bl_coh_wkb_invalid = (mt_coh_wkb_full < fl_b_bd);

% (k,a) invalid if coh(k,a,z) < bd for any z
ar_bl_wkb_invalid = max(mt_bl_coh_wkb_invalid,[], 2);
% mt_bl_wkb_invalid = reshape(ar_bl_wkb_invalid, size(mt_a));
mt_bl_wkb_invalid = reshape(ar_bl_wkb_invalid, [it_ak_perc_n, length(ar_w_level_full)*fl_z_r_infbr_n]);

% find the first w_level choice where some k(w) percent choices are valid?
ar_bl_w_level_invalid =  min(mt_bl_wkb_invalid, [], 1);

% w choices can not be lower than fl_w_level_min_valid. If w choices are
% lower, given the current borrowing interest rate as well as the minimum
% income level in the future, and the maximum borrowing level available
% next period, and given the shock distribution, there exists some state in
% the future when the household when making this choice will be unable to
% borrow sufficiently to maintain positive consumption.

ar_w_level_full_dup = repmat(ar_w_level_full, [1,fl_z_r_infbr_n]);
fl_w_level_min_valid = min(ar_w_level_full_dup(~ar_bl_w_level_invalid));

%% COH3: Update Valid 2nd stage choice matrix
% ar_w_level = linspace(fl_w_level_min_valid, fl_w_max, it_w_interp_n);
% ar_k_max = ar_w_level - fl_b_bd;
% mt_k = (ar_k_max'*ar_ak_perc)';
% mt_a = (ar_w_level - mt_k);
% ar_a_meshk = mt_a(:);
% ar_k_mesha = mt_k(:);

%% COH4: Select only Valid (k(w), a) choices

% mt_coh_wkb = mt_coh_wkb_full(~ar_bl_wkb_invalid, :);
% mt_z_wage_mesh_coh_wkb = repmat(ar_z, [size(mt_coh_wkb,1),1]);
% mt_z_r_infbr_mesh_coh_wkb = repmat(ar_z_r_infbr, [size(mt_coh_wkb,1),1]);

% it_ak_perc_n = length(ar_ak_perc);
% it_w_interp_n = length(ar_w_level);

mt_coh_wkb = mt_coh_wkb_full;
it_wak_n = size(mt_coh_wkb,1)/fl_z_r_infbr_n;

mt_coh_wkb_mesh_z_r_infbr = repmat(mt_coh_wkb_full, [1, fl_z_r_infbr_n]);
mt_z_r_infbr_mesh_coh_wkb = repmat(ar_z_r_infbr, [size(mt_coh_wkb,1),1]);

mt_z_wage_mesh_coh_wkb = repmat(ar_z_wage, [size(mt_coh_wkb,1),1]);
mt_z_mesh_coh_wkb = repmat((1:it_z_n), [size(mt_coh_wkb,1), 1]);
mt_z_mesh_coh_wkb_seg = repmat((1:it_z_n), [it_wak_n, 1]);

if (ismember(st_v_coh_z_interp_method, ["method_cell"]))
    
    cl_mt_coh_wkb_mesh_z_r_infbr = cell([fl_z_r_infbr_n, 1]);
    for it_z_r_infbr_ctr = 1:1:fl_z_r_infbr_n
        it_mt_val_row_start = it_wak_n*(it_z_r_infbr_ctr-1) + 1;
        it_mt_val_row_end = it_mt_val_row_start + it_wak_n - 1;
        cl_mt_coh_wkb_mesh_z_r_infbr{it_z_r_infbr_ctr} = ...
            mt_coh_wkb_mesh_z_r_infbr(it_mt_val_row_start:it_mt_val_row_end, :);
    end
    
elseif (ismember(st_v_coh_z_interp_method, ["method_idx_a", "method_idx_b"]))

    % This is borrowing with default or not condition
    fl_min_mt_coh = fl_b_bd;

    cl_mt_coh_wkb_mesh_z_r_infbr = cell([fl_z_r_infbr_n, 1]);
    for it_z_r_infbr_ctr = 1:1:fl_z_r_infbr_n
        it_mt_val_row_start = it_wak_n*(it_z_r_infbr_ctr-1) + 1;
        it_mt_val_row_end = it_mt_val_row_start + it_wak_n - 1;

        mt_coh_wkb_mesh_z_r_infbr_seg = ...
            1 + ((mt_coh_wkb_mesh_z_r_infbr(it_mt_val_row_start:it_mt_val_row_end, :) - fl_min_mt_coh)/fl_coh_interp_grid_gap);

        cl_mt_coh_wkb_mesh_z_r_infbr{it_z_r_infbr_ctr} = mt_coh_wkb_mesh_z_r_infbr_seg;

    end
    
end

%% Generate 1st Stage States: Interpolation Cash-on-hand Interpolation Grid
% For the iwkz problems, we solve the problem along a grid of cash-on-hand
% values, the interpolate to find v(k',b',z) at (k',b') choices. Crucially,
% we have to coh matrxies

% for highly persistent shock with high sd, this fl_max_mt_coh could get
% very high leading to out of memory error. So to resolve this, give this a
% bound. Which means some parameter that limits matrix size
fl_max_mt_coh = max(max(mt_coh_wkb));
if (fl_max_mt_coh > 0 )
    fl_max_mt_coh = min(fl_max_mt_coh, fl_w_max*5);    
end

% This is savings only condition
% fl_min_mt_coh = min(min(mt_coh_wkb));

% This could be condition if no defaults are allowed
% fl_min_mt_coh = fl_w_level_min_valid;

% This is borrowing with default or not condition
fl_min_mt_coh = fl_b_bd;

it_coh_interp_n = (fl_max_mt_coh-fl_min_mt_coh)/(fl_coh_interp_grid_gap);
ar_interp_coh_grid = fft_array_add_zero(linspace(fl_min_mt_coh, fl_max_mt_coh, it_coh_interp_n), true);
it_coh_interp_n = length(ar_interp_coh_grid);
[mt_interp_coh_grid_mesh_z_wage, mt_z_wage_mesh_interp_coh_grid] = ndgrid(ar_interp_coh_grid, ar_z_wage);
mt_interp_coh_grid_mesh_w_perc = repmat(ar_interp_coh_grid, [it_w_perc_n, 1]);

mt_interp_coh_grid_mesh_z = repmat(ar_interp_coh_grid', [1, it_z_n]);
mt_z_mesh_interp_coh_grid = repmat((1:it_z_n), [it_coh_interp_n, 1]);

%% Generate 1st Stage Choices: Interpolation Cash-on-hand Interpolation Grid
% previously, our ar_w was the first stage choice grid, the grid was the
% same for all coh levels. Now, for each coh level, there is a different
% ar_w. ar_interp_coh_grid is (1 by ar_interp_coh_grid) and ar_w_perc is (
% 1 by it_w_perc_n). Conditional on z, each choice matrix is (it_w_perc_n
% by ar_interp_coh_grid). Here we are pre-computing the choice matrix. This
% could be a large matrix if the choice grid is large. This is the matrix
% of aggregate savings choices
%

% 1. Given COH grid, w choices in terms of cash-on-hand percentages
if (fl_min_mt_coh < 0)
    % borrowing bound is below zero
    mt_w_perc_mesh_interp_coh_grid = ((ar_interp_coh_grid-fl_min_mt_coh)'*ar_w_perc)' + fl_min_mt_coh;
else
    % savings only
    mt_w_perc_mesh_interp_coh_grid = ((ar_interp_coh_grid)'*ar_w_perc)';
end

% 2. Some w < 0, some w > 0. When w < 0, coh > 0 or coh < 0 both possible.
% Need to interplate in ff_ipwkbzr_fibs_vecsv differently for w < 0 because
% there both w as well as coh matters, if coh < 0 and w < 0, a fraction of
% w goes to getting informal bridge loans.
mt_bl_w_perc_mesh_interp_coh_grid_wneg = (mt_w_perc_mesh_interp_coh_grid < 0);
mt_w_perc_mesh_interp_coh_grid_wneg = mt_w_perc_mesh_interp_coh_grid(mt_bl_w_perc_mesh_interp_coh_grid_wneg);
mt_w_perc_mesh_interp_coh_grid_wpos = mt_w_perc_mesh_interp_coh_grid(~mt_bl_w_perc_mesh_interp_coh_grid_wneg);

%% Generate 1st Stage Choices: Percent of W for Covering Bridge Loans
% If bridge loan does not matter, do not need to cover bridge loan. Then
% these percentages should reflect what happens when param_map('bl_bridge')
% = false, and, param_map('it_coh_bridge_perc_n') = 1;

% 1. Expand cash-on-hand by w_perc grid
mt_interp_coh_grid_mesh_w_perc = zeros(size(mt_w_perc_mesh_interp_coh_grid)) + ar_interp_coh_grid;

% 2. How much is coh as perc of w_perc grid level choice based on w_perc
mt_coh_w_perc_ratio = (1-(mt_interp_coh_grid_mesh_w_perc./mt_w_perc_mesh_interp_coh_grid));

% 3. The ratio only relevant for where w < 0 and where coh < 0. Note the
% ratio we want is: ar_coh_bridge_perc, which is percent of w NOT going to
% bridge.
mt_coh_w_perc_ratio(mt_interp_coh_grid_mesh_w_perc >= 0) = 1;
mt_coh_w_perc_ratio_wneg = mt_coh_w_perc_ratio(mt_bl_w_perc_mesh_interp_coh_grid_wneg);

%% Generate Interpolation Consumption Grid
% We also interpolate over consumption to speed the program up. We only
% solve for u(c) at this grid for the iwkz problmes, and then interpolate
% other c values.

fl_c_max = max(max(mt_coh_wkb_full)) - fl_b_bd;
it_interp_c_grid_n = (fl_c_max-fl_c_min)/(it_c_interp_grid_gap);
ar_interp_c_grid = linspace(fl_c_min, fl_c_max, it_interp_c_grid_n);

%% Initialize armt_map to store, state, choice, shock matrixes

armt_map = containers.Map('KeyType','char', 'ValueType','any');
armtdesc_map = containers.Map('KeyType','char', 'ValueType','any');

%% Store armt_map (1): base arrays
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. Dimensions are:
%
% # ar_interp_c_grid: 1 by I^c
% # ar_interp_coh_grid: 1 by I^{coh}
% # ar_w_level: 1 by I^{W=k+b}
% # ar_w_perc: 1 by P^{W=k+b}
% # ar_ak_perc: 1 by P^{k and b}
%
% more descriptions:
%
% # ar_interp_c_grid: 1 by I^c, 1st stage consumption interpolation
% # ar_interp_coh_grid: 1 by I^{coh}, 1st stage value function V(coh,z)
% # ar_w_level: 1 by I^{W=k+b}, 2nd stage k*(w,z) w grid. 2nd stage, level
% of w over which we solve the optimal percentage k' choices. Need to
% generate interpolant based on this so that we know optimal k* given
% ar_w_perc(coh) in the 1st stage
% # ar_w_perc: 1 by P^{W=k+b}, 1st stage w \in {w_perc(coh)} choice set.
% 1st stage, percentage w choice given coh, at each coh level the number of
% choice points is the same for this problem with
% percentage grid points.
% # ar_ak_perc: 1 by P^{k and b}, 2nd stage k \in {ask_perc(w,z)} set
%

armt_map('ar_interp_c_grid') = ar_interp_c_grid;
armt_map('ar_interp_coh_grid') = ar_interp_coh_grid;
armt_map('ar_w_level') = ar_w_level;
armt_map('ar_w_perc') = ar_w_perc;
armt_map('ar_ak_perc') = ar_ak_perc;

%% Store armt_map (2): 1st stage level coh on hand related arrays
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. Dimensions are:
%
% # mt_interp_coh_grid_mesh_z_wage: I^{coh} by M^w
% # mt_z_wage_mesh_interp_coh_grid: I^{coh} by M^w
% # mt_interp_coh_grid_mesh_w_perc: I^{coh} by P^{LAM=k+b}
% # mt_w_perc_mesh_interp_coh_grid: I^{coh} by P^{LAM=k+b}
%
% more descriptions:
%
% # *mt_w_perc_mesh_interp_coh_grid* 1st stage, generate w(coh, percent),
% meaning the level of w given coh and the percentage grid of ar_w_perc.
% Mesh this with the coh grid, Rows here correspond to percentage of w
% choices, columns correspond to cash-on-hand. The columns of cash-on-hand
% is determined by ar_interp_coh_grid, because we solve the 1st stage
% problem at that coh grid.
%

armt_map('mt_interp_coh_grid_mesh_z_wage') = mt_interp_coh_grid_mesh_z_wage;
armt_map('mt_z_wage_mesh_interp_coh_grid') = mt_z_wage_mesh_interp_coh_grid;

armt_map('mt_interp_coh_grid_mesh_w_perc') = mt_interp_coh_grid_mesh_w_perc;
armt_map('mt_w_perc_mesh_interp_coh_grid') = mt_w_perc_mesh_interp_coh_grid;

armt_map('mt_interp_coh_grid_mesh_z') = mt_interp_coh_grid_mesh_z;
armt_map('mt_z_mesh_interp_coh_grid') = mt_z_mesh_interp_coh_grid;


%% Store armt_map (3): 2nd stage reachable coh(k(w), a(w,k), z', r)
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. These are grids for 1st stage solution
%
% # mt_coh_wkb: ((P^{k}_{a>=0} + P^{k}_{a<0} x P^{w frac bridge} ) x I^w x M^r) by (M^z) matrix
% # mt_z_wage_mesh_coh_wkb: same as mt_coh_wkb
%

armt_map('mt_coh_wkb') = mt_coh_wkb_full;
armt_map('mt_z_wage_mesh_coh_wkb') = mt_z_wage_mesh_coh_wkb;

armt_map('mt_z_mesh_coh_wkb') = mt_z_mesh_coh_wkb;
armt_map('mt_z_wage_mesh_coh_wkb') = mt_z_wage_mesh_coh_wkb;

armt_map('cl_mt_coh_wkb_mesh_z_r_infbr') = cl_mt_coh_wkb_mesh_z_r_infbr;
armt_map('mt_z_mesh_coh_wkb_seg') = mt_z_mesh_coh_wkb_seg;

% armt_map('mt_z_r_borr_mesh_coh_wkb') = mt_z_r_borr_mesh_coh_wkb;

%% Store armt_map (4): 2nd stage additional arrays
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. These are grids for 1st stage solution
%
% # mt_k: (I^w) by (P^{k and b})
% # ar_a_meshk: 1 by (I^w x P^{k and b})
% # ar_k_mesha: 1 by (I^w x P^{k and b})
% # ar_aplusk_mesh: 1 by (I^w x P^{k and b})
% # it_ameshk_n: scalar
%

armt_map('mt_k') = mt_k;
armt_map('ar_a_meshk') = ar_a_meshk;
armt_map('ar_k_mesha') = ar_k_mesha;
armt_map('ar_aplusk_mesh') = ar_aplusk_mesh;
armt_map('it_ameshk_n') = length(ar_a_meshk);

%% Store armt_map (5): Shock Grids Arrays and Mesh
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. These are grids for 1st stage solution
%
% # ar_z_r_infbr: 1 by (M^r)
% # ar_z_r_infbr_prob: 1 by (M^r)
% # ar_z_wage: 1 by (M^z)
% # ar_z_wage_prob: 1 by (M^z)
% # ar_z_r_infbr_mesh_wage_w1r2: 1 by (M^z x M^r)
% # ar_z_wage_mesh_r_infbr_w1r2: 1 by (M^z x M^r)
% # ar_z_r_infbr_mesh_wage_r1w2: 1 by (M^r x M^z)
% # ar_z_wage_mesh_r_infbr_r1w2: 1 by (M^r x M^z)
%

armt_map('ar_z_r_infbr') = ar_z_r_infbr;
armt_map('ar_z_r_infbr_prob') = ar_z_r_infbr_prob;

armt_map('ar_z_wage') = ar_z_wage;
armt_map('ar_z_wage_prob') = ar_z_wage_prob;

armt_map('ar_z_r_infbr_mesh_wage_w1r2') = ar_z_r_infbr_mesh_wage_w1r2;
armt_map('ar_z_wage_mesh_r_infbr_w1r2') = ar_z_wage_mesh_r_infbr_w1r2;
armt_map('ar_z_r_infbr_mesh_wage_r1w2') = ar_z_r_infbr_mesh_wage_r1w2;
armt_map('ar_z_wage_mesh_r_infbr_r1w2') = ar_z_wage_mesh_r_infbr_r1w2;

armt_map('mt_z_trans') = mt_z_trans;


%% Store armt_map (6): W Share for Bridge Parameters
%
% # *ar_w_level_full*: in
% <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/solve/html/ff_ipwkbzr_vf_vecsv.html
% ff_ipwkbzr_vf_vecsv>, _ar_w_level_ and _ar_w_level_full_ were the same.
% Now have this thing which is stored (length(ar_w_level_full)) by
% (length(ar_z)). _ar_w_level_full_ includes not just different levels of
% _ar_w_level_, but also repeats the elements of _ar_w_level_ that are < 0
% by _it_coh_bridge_perc_n_ times, starting with what corresponds to 100
% percent of w should go to cover bridge loan, until 0 percent for w < 0,
% which then proceeds to w > 0. So the last segment of _ar_w_level_full_ is
% the same as ar_w_level: ar_w_level_full((end-length(ar_w_level)+1):end) =
% ar_w_level.
%

armt_map('ar_coh_bridge_perc') = ar_coh_bridge_perc;
armt_map('ar_w_level_full') = ar_w_level_full;
armt_map('ar_ameshk_tnext_with_r') = mt_ameshk_tnext_with_r;

armt_map('mt_w_level_neg_mesh_coh_bridge_perc') = mt_w_level_neg_mesh_coh_bridge_perc;
armt_map('mt_coh_bridge_perc_mesh_w_level_neg') = mt_coh_bridge_perc_mesh_w_level_neg;

armt_map('mt_bl_w_perc_mesh_interp_coh_grid_wneg') = mt_bl_w_perc_mesh_interp_coh_grid_wneg;
armt_map('mt_w_perc_mesh_interp_coh_grid_wneg') = mt_w_perc_mesh_interp_coh_grid_wneg;
armt_map('mt_w_perc_mesh_interp_coh_grid_wpos') = mt_w_perc_mesh_interp_coh_grid_wpos;
armt_map('mt_coh_w_perc_ratio_wneg') = mt_coh_w_perc_ratio_wneg;

%% Store armt_map (7): Formal Informal Arrays

armt_map('ar_forbrblk') = ar_forbrblk;
armt_map('ar_forbrblk_r') = ar_forbrblk_r;

%% Store Function Map

func_map = containers.Map('KeyType','char', 'ValueType','any');
func_map('f_util_log') = f_util_log;
func_map('f_util_crra') = f_util_crra;
func_map('f_util_standin') = f_util_standin;
func_map('f_util_standin_coh') = f_util_standin_coh;
func_map('f_prod') = f_prod;
func_map('f_inc') = f_inc;
func_map('f_coh') = f_coh;
func_map('f_coh_fbis') = f_coh_fbis;
func_map('f_coh_save') = f_coh_save;
func_map('f_cons') = f_cons;

%% Graph

if (bl_graph_funcgrids)

    %% Generate Limited Legends
    % 8 graph points, 2 levels of borrow rates, and 4 levels of rbr rates
    ar_it_z_r_infbr = ([1 round((fl_z_r_infbr_n)/2) (fl_z_r_infbr_n)]);
    ar_it_z_wage = ([1 round((it_z_wage_n)/2) (it_z_wage_n)]);

    % combine by index
    mt_it_z_graph = ar_it_z_wage' + it_z_wage_n*(ar_it_z_r_infbr-1);
    ar_it_z_graph = mt_it_z_graph(:)';
    ar_it_z_graph_zwage = ([1 round((it_z_wage_n)/4) 2*round((it_z_wage_n)/4) 3*round((it_z_wage_n)/4) (it_z_wage_n)]);

    % legends index final
    cl_st_legendCell = cellstr([num2str(ar_z_r_infbr_mesh_wage_w1r2', 'zr=%3.2f;'), ...
                                num2str(ar_z_wage_mesh_r_infbr_w1r2', 'zw=%3.2f')]);

    % legends index final full mat wage only
    cl_st_legendCell_zwage = cellstr([num2str(ar_z_wage', 'zw=%3.2f')]);
    
    %% Graph 1: a and k choice grid graphs
    % compare the figure here to the same figure in
    % <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_get_funcgrid.html
    % ffs_akz_get_funcgrid>. there the grid points are on an even grid,
    % half of the grid points have NA. for the grid here, the grid points
    % get denser as we get closer to low w = k'+b' levels. This is what is
    % different visually about percentage points based choice grid for the
    % 2nd stage problem.
    %
    % Plot end because earlier parts have repeating w and a levels due to
    % potentially bridge which are coh percentage dependent. This will only
    % plot out the grid basically when coh percentage for bridge loan = 0
    %

    figure('PaperPosition', [0 0 7 4]);
    hold on;

    it_col_end = size(mt_a, 2);
    it_col_start = size(mt_a, 2) - length(ar_w_level) + 1;

    chart = plot(mt_a(:,it_col_start:it_col_end), ...
                 mt_k(:,it_col_start:it_col_end), ...
                 'blue');

    clr = jet(numel(chart));
    for m = 1:numel(chart)
        set(chart(m),'Color',clr(m,:))
    end

    it_col_end = length(ar_a_meshk);
    it_col_start = length(ar_a_meshk) - length(ar_w_level)*it_ak_perc_n + 1;

%     if (length(ar_w_level_full) <= 100)
    scatter(ar_a_meshk(it_col_start:it_col_end), ...
            ar_k_mesha(it_col_start:it_col_end), ...
            3, 'filled', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b');
%     end
    if (length(ar_w_level) <= 100)
        gf_invalid_scatter = scatter(ar_a_meshk_full(ar_bl_wkb_invalid(it_col_start:it_col_end)),...
                                     ar_k_mesha_full(ar_bl_wkb_invalid(it_col_start:it_col_end)),...
                20, 'O', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black');
    end

    xline(0);
    yline(0);

    title({'Risky K Percentage Grids Given w=k+a (2nd Stage)'...
           '(Bridge Borrow Share = 0)'})
    ylabel('Capital Choice (mt\_k)')
    xlabel({'Borrowing (<0) or Saving (>0) (mt\_a)'...
        'Each Diagonal Line a Different w=k+a level'...
        'Percentage for Risky K along Each Diagonal'})

    legend2plot = fliplr([1 round(numel(chart)/3) round((2*numel(chart))/4)  numel(chart)]);
    legendCell = cellstr(num2str(ar_w_level', 'k+a=%3.2f'));

    if (length(ar_w_level) <= 100)
        chart(length(chart)+1) = gf_invalid_scatter;
        legendCell{length(legendCell) + 1} = 'Invalid: COH(a,b,z)<bar(b) some z';
        legend(chart([legend2plot length(legendCell)]), legendCell([legend2plot length(legendCell)]), 'Location', 'northeast');
    else
        legend(chart([legend2plot]), legendCell([legend2plot]), 'Location', 'northeast');
    end

    grid on;

    %% Graph 2: coh by shock
    % compare the figure here to the same figure in
    % <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_get_funcgrid.html
    % ffs_akz_get_funcgrid>. there the grid points are on an even grid.
    % Visually, one could see that the blue/red line segments here are
    % always the same length, but in the ffs_akz_get_funcgrid figure, they
    % are increasingly longer as we move towards the right. They are even
    % because the number of percentage points available is constant
    % regardless of w = k' + b' levels. But previously, the number of grid
    % points available is increasing as w increases since choice grid is
    % based on levels.
    %

    figure('PaperPosition', [0 0 7 4]);
    chart = plot(0:1:(size(mt_coh_wkb_full,1)-1), mt_coh_wkb_full);
    clr = jet(numel(chart));
    for m = 1:numel(chart)
        set(chart(m),'Color',clr(m,:))
    end

    % zero lines
    xline(0);
    yline(0);

    % invalid points separating lines
    yline_borrbound = yline(fl_b_bd);
    yline_borrbound.HandleVisibility = 'on';
    yline_borrbound.LineStyle = '--';
    yline_borrbound.Color = 'blue';
    yline_borrbound.LineWidth = 2.5;

    title('Cash-on-Hand given w(k+b),k,z');
    ylabel('Cash-on-Hand (mt\_coh\_wkb\_full)');
    xlabel({'Index of Cash-on-Hand Discrete Point (0:1:(size(mt\_coh\_wkb\_full,1)-1))'...
            'Super-Seg: borrow r; Seg: w bridge perc; Sub-Seg: w=k+b; within inc. k'...    
            'For each w and z, coh maximizing k is different'});

    cl_st_legendCell_here = cl_st_legendCell_zwage;

    cl_st_legendCell_here{length(cl_st_legendCell_here) + 1} = 'borrow-constraint';
    chart(length(chart)+1) = yline_borrbound;
    legend(chart([ar_it_z_graph_zwage length(cl_st_legendCell_here)]), ...
                  cl_st_legendCell_here([ar_it_z_graph_zwage length(cl_st_legendCell_here)]), 'Location', 'northwest');
    
    grid on;

    %% Graph 3: 1st State Aggregate Savings Choices by COH interpolation grids

    figure('PaperPosition', [0 0 7 4]);
    hold on;

    chart = plot(ar_interp_coh_grid, mt_w_perc_mesh_interp_coh_grid');

    clr = jet(numel(chart));
    for m = 1:numel(chart)
        set(chart(m),'Color',clr(m,:))
    end
    if (length(ar_interp_coh_grid) <= 100)
        [~, mt_interp_coh_grid_mesh_w_perc] = ndgrid(ar_w_perc, ar_interp_coh_grid);
        scatter(mt_interp_coh_grid_mesh_w_perc(:), mt_w_perc_mesh_interp_coh_grid(:), 3, 'filled', ...
            'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b');
    end

    % invalid points separating lines
    yline_borrbound = yline(fl_w_level_min_valid);
    yline_borrbound.HandleVisibility = 'on';
    yline_borrbound.LineStyle = '--';
    yline_borrbound.Color = 'red';
    yline_borrbound.LineWidth = 2.5;

    xline0 = xline(0);
    xline0.HandleVisibility = 'off';
    yline0 = yline(0);
    yline0.HandleVisibility = 'off';

    title({'Aggregate Savings Percentage Grids (1st Stage)' ...
           'y=mt\_w\_by\_interp\_coh\_interp\_grid, and, y=ar\_interp\_coh\_grid'});
    ylabel('1st Stage Aggregate Savings Choices');
    xlabel({'Cash-on-Hand Levels (Interpolation Points)'...
            'w(coh)>min-agg-save, coh(k(w),w-k)>=bar(b)'});

    legend2plot = fliplr([1 round(numel(chart)/3) round((2*numel(chart))/4)  numel(chart)]);
    legendCell = cellstr(num2str(ar_w_perc', 'ar w perc=%3.2f'));
    legendCell{length(legendCell) + 1} = 'min-agg-save';
    chart(length(chart)+1) = yline_borrbound;
    legend(chart([legend2plot length(legendCell)]), legendCell([legend2plot length(legendCell)]), 'Location', 'northwest');

    grid on;

end


%% Graph Details, Generally do Not Run
if (bl_graph_funcgrids_detail)

    %% Graph 1: 2nd stage coh reached by k' b' choices by index

    figure('PaperPosition', [0 0 7 4]);
    ar_coh_kpzgrid_unique = unique(sort(mt_coh_wkb_full(:)));
    scatter(1:length(ar_coh_kpzgrid_unique), ar_coh_kpzgrid_unique);
    xline(0);
    yline(0);
    title('Cash-on-Hand given w(k+b),k,z');
    ylabel('Cash-on-Hand (y=ar\_coh\_kpzgrid\_unique)');
    xlabel({'Index of Cash-on-Hand Discrete Point' 'x = 1:length(ar\_coh\_kpzgrid\_unique)'});
    grid on;

    %% Graph 2: 2nd stage coh reached by k' b' choices  by coh

    figure('PaperPosition', [0 0 7 4]);
    ar_coh_kpzgrid_unique = unique(sort(mt_coh_wkb_full(:)));
    scatter(ar_coh_kpzgrid_unique, ar_coh_kpzgrid_unique, '.');
    xline(0);
    yline(0);
    title('Cash-on-Hand given w(k+b),k,z; See Clearly Sparsity Density of Grid across Z');
    ylabel('Cash-on-Hand (y = ar\_coh\_kpzgrid\_unique)');
    xlabel({'Cash-on-Hand' 'x = ar\_coh\_kpzgrid\_unique'});
    grid on;
end

%% Display

if (bl_display_funcgrids)

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_z_wage');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(ar_z_wage));
    disp(ar_z_wage);

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_w_level_full');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(ar_w_level_full));
    disp(ar_w_level_full);

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_w_by_interp_coh_interp_grid');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_w_perc_mesh_interp_coh_grid));
    disp(head(array2table(mt_w_perc_mesh_interp_coh_grid), 10));
    disp(tail(array2table(mt_w_perc_mesh_interp_coh_grid), 10));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_z_trans');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_z_trans));
    disp(head(array2table(mt_z_trans), 10));
    disp(tail(array2table(mt_z_trans), 10));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_interp_coh_grid');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    summary(array2table(ar_interp_coh_grid'));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_interp_c_grid');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    summary(array2table(ar_interp_c_grid'));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_interp_coh_grid_mesh_z');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_interp_coh_grid_mesh_z));
    disp(head(array2table(mt_interp_coh_grid_mesh_z), 10));
    disp(tail(array2table(mt_interp_coh_grid_mesh_z), 10));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_a');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_a));
    disp(head(array2table(mt_a), 10));
    disp(tail(array2table(mt_a), 10));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_a_meshk');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    summary(array2table(ar_a_meshk));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('mt_k');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(size(mt_k));
    disp(head(array2table(mt_k), 10));
    disp(tail(array2table(mt_k), 10));

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('ar_k_mesha');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    summary(array2table(ar_k_mesha));

    param_map_keys = keys(func_map);
    param_map_vals = values(func_map);
    for i = 1:length(func_map)
        st_display = strjoin(['pos =' num2str(i) '; key =' string(param_map_keys{i}) '; val =' func2str(param_map_vals{i})]);
        disp(st_display);
    end

end

%% Display

if (bl_display_funcgrids)
    fft_container_map_display(armt_map, it_display_summmat_rowmax, it_display_summmat_colmax);
    fft_container_map_display(func_map, it_display_summmat_rowmax, it_display_summmat_colmax);
end

end
