
function drug_dosage_gui_step1()

  f = figure('Position', [100 100 1100 600], 'Name', 'Drug Dosage Modeling', ...
             'Color', [0.9 0.9 0.9], 'Resize', 'off');

  ax = axes('Parent', f, 'Units', 'pixels', 'Position', [330 70 720 500]);

  %% === المدخلات ===
  labels = {'Initial Concentration (C0)', 'Elimination Rate (k)', ...
            'Total Time (T)', 'Time Step (h)'};
  tooltips = {'Initial drug concentration in the blood.', ...
              'Elimination rate constant.', ...
              'Total duration of simulation (in hours).', ...
              'Step size (time increment in hours).'};
  defaults = {'50', '0.1', '24', '1'};
  boxes = cell(1,4);

  for i = 1:4
      uicontrol('Style', 'text', 'String', labels{i}, ...
          'Position', [20 560-(i-1)*40 180 20], 'BackgroundColor', [0.9 0.9 0.9], ...
          'HorizontalAlignment', 'left');
      boxes{i} = uicontrol('Style', 'edit', ...
          'Position', [200 560-(i-1)*40 100 25], ...
          'String', defaults{i}, 'TooltipString', tooltips{i});
  end

  %% === Checkboxes ===
  exact_chk = uicontrol('Style','checkbox','String','Show Exact Solution', ...
      'Position',[20 400 200 25], 'Value', 0, ...
      'TooltipString', 'Toggle the exact solution curve.', ...
      'BackgroundColor', [0.9 0.9 0.9], 'Callback', @plot_exact);

  show_all_chk = uicontrol('Style','checkbox','String','Show All Methods', ...
      'Position',[20 370 200 25], 'Value', 0, ...
      'TooltipString', 'Display all numerical methods together.', ...
      'BackgroundColor', [0.9 0.9 0.9], 'Callback', @plot_all);

  %% === Buttons ===
  method_names = {'Forward Euler', 'Backward Euler', 'Heun''s Method', 'Midpoint Method', ...
                  'Runge-Kutta', 'Adams-Bashforth', 'Adams-Moulton'};
  method_callbacks = {@plot_forward, @plot_backward, @plot_heun, @plot_midpoint, ...
                      @plot_runge_kutta, @plot_adams_bashforth, @plot_adams_moulton};

  for i = 1:length(method_names)
      uicontrol('Style','pushbutton','String',method_names{i}, ...
          'TooltipString', ['Toggle ' method_names{i} ' curve.'], ...
          'Position',[20 330-(i-1)*35 200 30], 'Callback', method_callbacks{i});
  end

  %% === Additional Buttons ===
  uicontrol('Style','pushbutton','String','Clear Plot', ...
    'Position',[20 60 100 30], ...
    'BackgroundColor', [0.6 0.2 0.2], 'ForegroundColor', 'white', ...
    'TooltipString', 'Clear the plot and reset selections.', ...
    'Callback', @clear_plot);

  uicontrol('Style','pushbutton','String','Save Plot', ...
    'Position',[140 60 100 30], ...
    'TooltipString', 'Save the current plot as a PNG image.', ...
    'Callback', @save_plot);

  uicontrol('Style','pushbutton','String','Export CSV', ...
    'Position',[20 20 100 30], ...
    'TooltipString', 'Export the time and concentration values as CSV.', ...
    'Callback', @export_csv);

  uicontrol('Style','pushbutton','String','Reset Inputs', ...
    'Position',[140 20 100 30], ...
    'TooltipString', 'Reset all inputs to default values.', ...
    'Callback', @reset_inputs);

  %% === Functions ===
  function [C0, k, T, h, t, N] = read_inputs()
      C0 = str2double(get(boxes{1}, 'String'));
      k  = str2double(get(boxes{2}, 'String'));
      T  = str2double(get(boxes{3}, 'String'));
      h  = str2double(get(boxes{4}, 'String'));
      if isnan(C0) || isnan(k) || isnan(T) || isnan(h) || C0 <= 0 || k <= 0 || T <= 0 || h <= 0
          errordlg('All inputs must be positive numeric values.');
          t = []; N = 0;
          return;
      end
      t = 0:h:T;
      N = length(t) - 1;
  end

  function clear_plot(~,~)
      cla(ax, 'reset');
      set(exact_chk, 'Value', 0);
      set(show_all_chk, 'Value', 0);
      legend(ax, 'off');
  end

  function reset_inputs(~,~)
      defaults = {'50', '0.1', '24', '1'};
      for i = 1:4
          set(boxes{i}, 'String', defaults{i});
      end
  end

  function plot_all(~,~)
    if get(show_all_chk, 'Value')
        cla(ax, 'reset'); pause(0.01);
        hold(ax, 'on');
        [C0, k, ~, h, t, N] = read_inputs();
        if isempty(t), return; end

        % الحل الحقيقي
        C_exact = C0 * exp(-k * t);
        plot(ax, t, C_exact, 'k-', 'LineWidth', 2, 'DisplayName', 'Exact');

        % الطرق العددية
        methods = {@forward_euler, @backward_euler, @heuns_method, @midpoint_method, ...
                   @runge_kutta, @adams_bashforth, @adams_moulton};
        names = {'Forward Euler', 'Backward Euler', 'Heun''s Method', 'Midpoint Method', ...
                 'Runge-Kutta', 'Adams-Bashforth', 'Adams-Moulton'};
        styles = {'b-o','r-o','g-o','m-o','c-o','y-o','o-'};
        colors = {'b','r','g','m','c','y',[1 0.5 0]};

        for i = 1:length(methods)
            C = methods{i}(k, C0, h, N);
            plot(ax, t, C, styles{i}, 'DisplayName', names{i}, 'Color', colors{i});
        end

        update_legend();
    else
        cla(ax);
    end
end


  function save_plot(~,~)
      [file, path] = uiputfile('plot.png', 'Save Plot As');
      if file
          saveas(ax, fullfile(path, file));
      end
  end

  function export_csv(~,~)
      [C0, k, T, h, t, N] = read_inputs();
      if isempty(t), return; end
      C_exact = C0 * exp(-k * t);
      data = [t(:), C_exact(:)];
      [file, path] = uiputfile('data.csv', 'Export CSV');
      if file
          csvwrite(fullfile(path, file), data);
      end
  end

  function plot_exact(~,~)
      existing = findall(ax, 'Type', 'line', 'DisplayName', 'Exact');
      if get(exact_chk, 'Value')
          if isempty(existing)
              [C0, k, ~, ~, t, ~] = read_inputs();
              C = C0 * exp(-k * t);
              plot(ax, t, C, 'k-', 'LineWidth', 2, 'DisplayName', 'Exact');
              update_legend();
          end
      else
          delete(existing);
          update_legend();
      end
  end

  function toggle_plot(name, method, style, color)
    cla(ax, 'reset');  % امسح القديم كله الأول
    [C0, k, ~, h, t, N] = read_inputs();
    if isempty(t), return; end
    C = method(k, C0, h, N);
    if nargin < 4
        plot(ax, t, C, style, 'DisplayName', name);
    else
        plot(ax, t, C, style, 'Color', color, 'DisplayName', name);
    end
    update_legend();
end


function plot_forward(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Forward Euler', @forward_euler, 'b-o');
end

function plot_backward(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Backward Euler', @backward_euler, 'r-o');
end

function plot_heun(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Heun''s Method', @heuns_method, 'g-o');
end

function plot_midpoint(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Midpoint Method', @midpoint_method, 'm-o');
end

function plot_runge_kutta(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Runge-Kutta', @runge_kutta, 'c-o');
end

function plot_adams_bashforth(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Adams-Bashforth', @adams_bashforth, 'y-o');
end

function plot_adams_moulton(~,~)
    if get(show_all_chk, 'Value'), return; end
    cla(ax, 'reset');
    toggle_plot('Adams-Moulton', @adams_moulton, 'o-', [1 0.5 0]);
end


  function update_legend()
      h_lines = findall(ax, 'Type', 'line');
      if isempty(h_lines), return; end
      names = get(h_lines, 'DisplayName');
      if ischar(names), names = {names}; end
      names = fliplr(names);
      legend(ax, names, 'Location', 'northeast');
      title(ax, 'Drug Dosage Modeling');
      xlabel(ax, 'Time (hours)');
      ylabel(ax, 'Concentration (mg/L)');
      grid(ax, 'on');
  end
end

% === Numerical Methods ===
function C = forward_euler(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    for n = 1:N
        C(n+1) = C(n) + h * (-k * C(n));
    end
end

function C = backward_euler(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    for n = 1:N
        C(n+1) = C(n) / (1 + h * k);
    end
end

function C = heuns_method(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    for n = 1:N
        C_predict = C(n) - h * k * C(n);
        C(n+1) = C(n) - h * k * (C(n) + C_predict) / 2;
    end
end

function C = midpoint_method(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    for n = 1:N
        C_mid = C(n) - h * k * C(n) / 2;
        C(n+1) = C(n) - h * k * C_mid;
    end
end

function C = runge_kutta(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    for n = 1:N
        k1 = -k * C(n);
        k2 = -k * (C(n) + 0.5 * h * k1);
        k3 = -k * (C(n) + 0.5 * h * k2);
        k4 = -k * (C(n) + h * k3);
        C(n+1) = C(n) + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end

function C = adams_bashforth(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    if N < 2
        C = forward_euler(k, C0, h, N); return;
    end
    C(2) = C(1) + h * (-k * C(1));
    for n = 2:N
        C(n+1) = C(n) + h * (3/2 * (-k * C(n)) - 1/2 * (-k * C(n-1)));
    end
end

function C = adams_moulton(k, C0, h, N)
    C = zeros(1, N+1); C(1) = C0;
    if N < 2
        C = forward_euler(k, C0, h, N); return;
    end
    C(2) = C(1) + h * (-k * C(1));
    C(3) = C(2) + h * (-k * C(2));
    for n = 3:N
        f_n   = -k * C(n);
        f_n1  = -k * C(n-1);
        f_n2  = -k * C(n-2);
        C(n+1) = C(n) + h * (5*f_n + 8*f_n1 - f_n2)/12;
    end
end

