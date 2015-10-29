% Answers the design question of what kind of material will be the most
% cost effective and efficient for a solar cooker.
function solar_cooker()
% Models the internal energy of the surface of a pot and the water inside
% of it over time, heated from the sun's solar energy.
    insolation = 5; %kWh/m^2/day
    radius_cooker = 2;
    depth_cooker = 0.5;
    A_cooker = pi * radius_cooker / 6 / depth_cooker^2 * ...
        ((radius_cooker^2 + 4 * depth_cooker^2)^(3/2) - ...
        radius_cooker^3) % m^2
    k = 150; % W/m/K average of cast iron conductivity
    radius_pot = 0.3; %m inner radius where water is at
    height_water = 0.2; %m
    height_pot = 0.3; %m
    density_pot = 1300; % kg / m^3
    d = 0.01; %m
    mass_pot = pi * (radius_pot + d)^2 * height_pot * density_pot;
    c_pot = 500; % J / (kg * K)
    % assuming the pot is a cylinder, short and stout with the lid on
    SA_pot_in = 2 * pi * radius_pot * height_pot + 2 * pi * radius_pot^2;
    SA_pot_out = 2 * pi * (radius_pot + d) * height_pot...
        + 2 * pi * (radius_pot + d)^2;
    mass_water = pi * radius_pot^2 * height_water; %density is 1 kg/m^3
    c_water = 4186; % J /(kg * K)
    Tenv = 273 + 30; % K
    Twater = 273 + 15; % CHANGE LATA
    e = 0.97; % reflection efficiency %%CAN MODIFY TO TAKE INTO ACCOUNT
    % DIFFERENT COOKER SHAPES
    Tboil = 100 + 273; %K
    
    emmisivity = 0.65; % of cast iron
    sigma = 5.67e-8; %w/m^2/K Stephen Boltzmann's constnat
    h = k / d; % heat transfer coefficient of pot
    
    function res = change_U_system(t, internal_energies)
        % Params: internal energy of pot, internal energy of water
        temp_pot = internal_energies(1) / mass_pot / c_pot;
        temp_water = internal_energies(2) / mass_water / c_water;
        % Assume that the surface area of the cooker is 1 m^2
        % 1 - emmisivity percent of the radiated energy is reflected from
        % the pot. Therefore, only a certain percentage, corresponding to
        % emmisivity is actually absorbed into the pot and available for us
        % of conduction and convection and then radiation outward
        Qsolar = insolation / 24 / 3600 * A_cooker * 3.6e6;  % J
        radiation = Qsolar * e * emmisivity;
        % convection depends on the outside surface area in contact with the
        % environment
        % WILL IGNORE CONVECTION FOR NOW
        % convection = h * SA_pot_out * (Tenv - temp_pot);
        % conduction depends on the surface area of pot touching the inside
        conduction = k * SA_pot_in / d * (temp_pot - temp_water)...
             * (temp_water < 373);
%          fprintf('Water temp: %d\nConduction amount: %d\n\n', temp_water,...
%              conduction)
        % whatever energy is absorbed into the pot is also emmitted through
        % radiation outwards
        emmission = emmisivity * sigma * SA_pot_out * (temp_pot^4 - Tenv^4);
        res = [radiation - conduction - emmission; ...
            conduction];
    end

    function res = get_time_to_boil(reflection_efficiency, cooker_SA)
        A_cooker = cooker_SA;
        e = reflection_efficiency;
        
        % Make event that will stop ode45 when the water boils
        [t, u, TE, UE] = ode23(@change_U_system, [0, 50000], [Tenv * mass_pot * c_pot, ...
        Twater * mass_water * c_water], options);
        res = TE;
        if isempty(TE)
            res = -1;
        end
        
       
    end

    options = odeset('Events', @is_boiling);    
    % Set trigger to go off when the water reaches boiling
    function [value, isterminal, direction] = is_boiling(t, internal_energies)
           %disp(internal_energies(2) / mass_water / c_water)
           % When value = 0, event is triggered
           value = internal_energies(2) - Tboil * mass_water * c_water;
           isterminal = 1; % stop function as soon as this event is reached
           direction = 0; % At any zero (when value = 0) consider this event, not 
                          % only when the function is either increasing (1) or 
                          % decreasing (-1)
    end
    %Katya is beautiful
    function plot_cooker_specs()
%        cooker_SA = 8 : 10; % m^2
%        reflection_efficiency = 0.95 : 0.01 : 0.99;
%        Z = [0, 0, 0];
%        for a = cooker_SA
%            for ee = reflection_efficiency
%                T = get_time_to_boil(ee, a);
%                fprintf('Reflectivity: %d, area : %d, time to boil: %d\n', ee, a, T)
%                Z = [Z ; [a, ee, T]];
%            end
%        end
%        contourf(Z);
        %cooker_SA = 1 : 10;
        reflection_efficiency = 0.85 : 0.01 : 0.99;
        for i = 1 : length(reflection_efficiency)
            t = get_time_to_boil(emmisivity, reflection_efficiency(i));
            T(i) = t;
        end
        plot(reflection_efficiency, T);
    end
    
%     [t, u] = ode45(@change_U_system, [0, 100000], [Tenv * mass_pot * c_pot, ...
%         Twater * mass_water * c_water], options);
%     % Plot temperature of water vs time
%     figure(1)
%     plot(t / 60, u(:, 2) / mass_water / c_water - 273)
%     % Plot temperature of POT vs time
%     figure(2)
%     plot(t / 60, u(:, 1) / mass_pot / c_pot - 273)

%    get_time_to_boil(e, A_cooker)
    figure(3)
    plot_cooker_specs;

end