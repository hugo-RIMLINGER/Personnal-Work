bias_mA = 56.2;

%dbm
received_power_dbm = [-9.95,-10.94,-11.90,-12.95,-13.90,-14.87,-15.86,-16.87,-17.85,-18.82,-19.83,-20.84,-21.85,-22.85,-23.84,-24.87,-25.84,-26.85,-27.85,-28.84,-29.85,-30.82,-31.83,-32.81,-33.82,-34.82,-35.85,-36.80,-37.83,-38.82,-39.82,-40.80,-41.82,-42.82,-43.82,-44.83,-45.76,-46.76,-47.77,-48.78,-49.77,-50.76,-51.76,-52.77,-53.76,-54.79,-55.75,-56.81,-57.80,-58.82];

%db
attenuation = 1.08:1:50.08;


p = polyfit(attenuation,received_power_dbm,1);
test = p(1).*attenuation + p(2);


figure (1)
plot(attenuation,received_power_dbm,attenuation,test);

xlabel('attenuation (db)');
ylabel('received power (dbm)');
title('received power function of attenuation');

p = polyfit(attenuation,received_power_dbm,1);
