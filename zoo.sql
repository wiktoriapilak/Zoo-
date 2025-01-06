DROP TABLE strefy CASCADE;
CREATE TABLE strefy
(
id_strefy INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
nazwa_strefy VARCHAR(20) NOT NULL UNIQUE
);

DROP TABLE wybiegi CASCADE;
CREATE TABLE wybiegi
( 
nazwa_wybiegu VARCHAR(20) PRIMARY KEY, 
id_strefy INTEGER NOT NULL,  
CONSTRAINT FK_wybiegi_strefy FOREIGN KEY (id_strefy) 
REFERENCES Strefy(id_strefy) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE gatunki CASCADE;
CREATE TABLE Gatunki
( 
nazwa_gatunku VARCHAR(20) PRIMARY KEY, 
nazwa_wybiegu VARCHAR(20) NOT NULL, 
max_ilosc_zwierzat INTEGER NOT NULL,
CONSTRAINT FK_gatunki_wybiegi FOREIGN KEY (nazwa_wybiegu) 
REFERENCES wybiegi(nazwa_wybiegu) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE zwierzeta CASCADE;
CREATE TABLE Zwierzeta
(
id_zwierzecia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
imie VARCHAR(20) NOT NULL UNIQUE,
nazwa_gatunku VARCHAR(20) NOT NULL, 
data_urodzenia DATE NOT NULL, 
plec CHAR,
czy_w_lecznicy BOOLEAN NOT NULL DEFAULT FALSE,
CONSTRAINT FK_zwierzeta_gatunki FOREIGN KEY (nazwa_gatunku)
REFERENCES gatunki(nazwa_gatunku) ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE historia_lecznicy CASCADE;
CREATE TABLE Historia_lecznicy
(
id_wpisu INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
id_zwierzecia INTEGER NOT NULL, 
data_wpisania DATE NOT NULL, 
data_wypisania DATE NULL, 
uwagi VARCHAR(100) NULL,  
CHECK(data_wypisania>=data_wpisania), 
CONSTRAINT FK_historia_lecznicy_zwierzeta FOREIGN KEY (id_zwierzecia) 
REFERENCES zwierzeta(id_zwierzecia) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE bilety CASCADE;
CREATE TABLE bilety
( 
nazwa_biletu VARCHAR(20) PRIMARY KEY, 
cena NUMERIC(7,2) NOT NULL
);

DROP TABLE historia_wejsc CASCADE;
CREATE TABLE historia_wejsc
(
id_wstepu INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
data_wstepu DATE NOT NULL, 
nazwa_biletu VARCHAR(20) NOT NULL, 
CONSTRAINT FK_historia_zwiedzania_bilety FOREIGN KEY (nazwa_biletu)
REFERENCES bilety(nazwa_biletu)
);

DROP TABLE stanowiska CASCADE;
CREATE TABLE stanowiska
(
nazwa_stanowiska VARCHAR(50) PRIMARY KEY, 
wynagrodzenie NUMERIC(7,2) NOT NULL
);

DROP TABLE pracownicy CASCADE;
CREATE TABLE pracownicy
(
id_pracownika INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
Imie VARCHAR(50) NOT NULL, 
Nazwisko VARCHAR(50) NOT NULL, 
nazwa_stanowiska VARCHAR(20) NOT NULL,
id_strefy INTEGER,
data_zatrudnienia DATE NOT NULL,
CONSTRAINT FK_pracownicy_strefy FOREIGN KEY (id_strefy) REFERENCES Strefy(id_strefy),
CONSTRAINT FK_pracownicy_stanowiska FOREIGN KEY (nazwa_stanowiska)
REFERENCES Stanowiska(nazwa_stanowiska) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP VIEW w_lecznicy CASCADE;
CREATE VIEW w_lecznicy AS SELECT nazwa_strefy AS "strefa", nazwa_gatunku AS "gatunek", 
imie, data_wpisania AS "od", data_wypisania AS "do", uwagi
FROM historia_lecznicy JOIN zwierzeta USING(id_zwierzecia) JOIN gatunki USING(nazwa_gatunku) 
JOIN wybiegi USING(nazwa_wybiegu) JOIN strefy USING(id_strefy)
WHERE data_wypisania IS NULL;

DROP VIEW zdrowe_zwierzeta CASCADE;
CREATE VIEW zdrowe_zwierzeta AS SELECT imie, nazwa_gatunku AS "gatunek",
data_urodzenia AS "data urodzenia", plec, nazwa_wybiegu AS "wybieg", nazwa_strefy
AS "strefa" FROM zwierzeta JOIN gatunki USING(nazwa_gatunku) JOIN wybiegi USING(nazwa_wybiegu) 
JOIN strefy USING(id_strefy) WHERE czy_w_lecznicy = 'f';

DROP VIEW historia_choroby CASCADE;
CREATE VIEW historia_choroby AS SELECT imie, data_wpisania AS "od", data_wypisania AS "do",
uwagi FROM historia_lecznicy JOIN zwierzeta USING(id_zwierzecia);

DROP VIEW zatrudnieni CASCADE;
CREATE VIEW zatrudnieni AS SELECT id_pracownika AS "nr", imie, nazwisko, nazwa_stanowiska 
AS "stanowisko", nazwa_strefy AS "strefa" FROM pracownicy LEFT JOIN
strefy USING(id_strefy) JOIN stanowiska USING(nazwa_stanowiska);

DROP VIEW historia_biletow CASCADE;
CREATE VIEW historia_biletow AS SELECT data_wstepu AS "data", nazwa_biletu AS "nazwa biletu"
FROM historia_wejsc JOIN bilety USING(nazwa_biletu);

DROP VIEW ilosc_zwierzat CASCADE;
CREATE VIEW ilosc_zwierzat AS SELECT nazwa_gatunku, count(*) AS ilosc from zwierzeta
GROUP BY nazwa_gatunku;

DROP VIEW dostepne_miejsca CASCADE;
CREATE VIEW dostepne_miejsca AS SELECT nazwa_gatunku, max_ilosc_zwierzat - ilosc 
FROM ilosc_zwierzat JOIN gatunki USING(nazwa_gatunku);

DROP VIEW niezapelnione_gatunki CASCADE;
CREATE VIEW niezapelnione_gatunki AS SELECT nazwa_gatunku, ilosc FROM ilosc_zwierzat
JOIN gatunki USING(nazwa_gatunku) WHERE ilosc < max_ilosc_zwierzat;


CREATE OR REPLACE FUNCTION ile_zwierzat_w() RETURNS trigger AS $$ 
DECLARE 
	maks INTEGER;
	ile INTEGER;
	krotka RECORD;
BEGIN 
	FOR krotka IN SELECT nazwa_gatunku FROM zwierzeta LOOP 
		SELECT count(*) INTO ile FROM zwierzeta WHERE 		nazwa_gatunku=NEW.nazwa_gatunku;
	END LOOP;
	SELECT max_ilosc_zwierzat INTO maks FROM gatunki WHERE 	nazwa_gatunku=NEW.nazwa_gatunku;
	IF (ile=maks) THEN 
		RAISE NOTICE'Osiagnieto maksymalna ilosc zwierzat tego gatunku';
		RETURN OLD;
	ELSE 
		RAISE NOTICE'Zwierze zostalo pomyslnie dodane do bazy';
	END IF;
	RETURN NEW;
	
END;
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER policz
BEFORE INSERT ON zwierzeta
FOR EACH ROW EXECUTE
PROCEDURE
ile_zwierzat_w();

CREATE OR REPLACE FUNCTION dodaj_zwierze(imie_x VARCHAR(20), nazwa_gatunku_X VARCHAR(20), 
data_urodzenia_x DATE, plec_X CHAR) RETURNS VOID AS $$

BEGIN 
	INSERT INTO zwierzeta (imie, nazwa_gatunku, data_urodzenia, plec) VALUES 
		(imie_x, nazwa_gatunku_x, data_urodzenia_x, plec_x);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION usun_zwierze(imie_x VARCHAR(20)) RETURNS VOID AS $$
BEGIN
	DELETE FROM zwierzeta WHERE imie = imie_x;
	RAISE NOTICE'Usunieto zwierze z bazy danych';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION przenies_do_lecznicy(imie_x VARCHAR(20), data_x DATE,
uwagi_x VARCHAR(100)) RETURNS VOID AS $$
DECLARE
	id_x INTEGER;

BEGIN 
	SELECT id_zwierzecia INTO id_x FROM zwierzeta WHERE imie = imie_x;
	INSERT INTO historia_lecznicy (id_zwierzecia, data_wpisania, uwagi)
		VALUES (id_x, data_x, uwagi_x);
	UPDATE zwierzeta SET czy_w_lecznicy='t' WHERE id_zwierzecia = id_x;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION wypisz_zwierze(imie_x VARCHAR(20), data_x date) RETURNS VOID AS $$
DECLARE 
	id INTEGER;
BEGIN 
	SELECT id_zwierzecia INTO id FROM zwierzeta WHERE imie_x=imie;
	UPDATE historia_lecznicy SET data_wypisania=data_x
		WHERE id_zwierzecia=id;
	UPDATE zwierzeta SET czy_w_lecznicy='f' 
		WHERE id_zwierzecia=id;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zatrudnij_pracownika(Imie_x VARCHAR(50), 
Nazwisko_x VARCHAR(50), 
nazwa_stanowiska_x  VARCHAR(20),
nazwa_strefy_x  VARCHAR(20),
data_zatrudnienia_x DATE) RETURNS VOID AS $$
DECLARE
	id_strefx INTEGER;
BEGIN 
	SELECT id_strefy INTO id_strefx FROM strefy WHERE nazwa_strefy = nazwa_strefy_x;
	INSERT INTO pracownicy (Imie, Nazwisko, nazwa_stanowiska, id_strefy, data_zatrudnienia)
		VALUES (imie_x, Nazwisko_x, nazwa_stanowiska_x, id_strefx, data_zatrudnienia_x);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zwolnij_pracownika(Id_x INTEGER) RETURNS VOID AS $$
BEGIN 
	DELETE FROM pracownicy WHERE id_pracownika=Id_x;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zysk(pocz DATE, kon DATE) RETURNS INTEGER AS $$
DECLARE
	suma_x INTEGER;
	krotka_x RECORD;
BEGIN 
		SELECT sum(cena) INTO suma_x FROM bilety JOIN historia_wejsc USING(nazwa_biletu) 
			WHERE data_wstepu BETWEEN pocz AND kon;

	RETURN suma_x;
END;
$$ LANGUAGE 'plpgsql';


INSERT INTO strefy (nazwa_strefy) VALUES
	 ('Tundra'),
	 ('Tajga'),
	 ('Sawanna'),
	 ('Pustynia'),
	 ('Tropiki'),
	 ('Ptaszarium '),
	 ('Oceanarium');

INSERT INTO wybiegi(nazwa_wybiegu,id_strefy) VALUES
	 ('Wilk szary',1),
	 ('Renifer tundrowy',1),
	 ('Panda wielka',2),
	 ('Pandka ruda',2),
	 ('Tygrys syberyjski',2),
	 ('Gepard',3),
	 ('Lew',3),
	 ('Hipopotam',3),
	 ('Fenek pustynny',4),
	 ('Likaon pstry',4),
	 ('Goryl nizinny',5),
	 ('Lemury',5),
	 ('Sekretarz',6),
	 ('Jaszczurnik',6),
	 ('Harpia wielka',6),
	 ('Orlik malajski',6),
	 ('Sowica ciemnolica',6),
	 ('Uszatka zwyczajna',6),
	 ('Pirania',7),
	 ('Murena zebra',7),
	 ('Murena olbrzymia',7),
	 ('Ognica pstra',7),
	 ('Akwarium1',7),
	 ('Akwarium2',7),
	 ('Akwarium3',7),
	 ('Akwarium4',7),
	 ('Niedzwiedz brunatny',1),
	 ('Niedzwiedz grizzly',1),
	 ('Makak japonski',2),
	 ('Safari',3),
	 ('Nosorozec indyjski',3),
	 ('Flaming rozowy',3),
	 ('Surykatka i mrownik',3),
	 ('Orangutan borneanski',5),
	 ('Krokodyl rozancowy',5),
	 ('Zolw olbrzymi',5),
	 ('Papuzki',6),
	 ('Rybolow zwyczajny',6),
	 ('Orzel plamisty',6),
	 ('Plomykowka zwyczajna',6),
	 ('Plomykowka ziemna',6),
	 ('Szlaroglowka',6),
	 ('Syczon krzykliwy',6),
	 ('Stretwa',7),
	 ('Bizon i widlorog',2),
	 ('Slon afrykanski',4),
	 ('Wielblad dwugarbny',4);

INSERT INTO gatunki (nazwa_gatunku,nazwa_wybiegu,max_ilosc_zwierzat) VALUES
	 ('Niedzwiedz brunatny','Niedzwiedz brunatny',2),
	 ('Niedzwiedz grizzly','Niedzwiedz grizzly',2),
	 ('Wilk szary','Wilk szary',12),
	 ('Renifer tundrowy','Renifer tundrowy',10),
	 ('Bizon amerykanski','Bizon i widlorog',5),
	 ('Widlorog amerykanski','Bizon i widlorog',7),
	 ('Makak japonski','Makak japonski',15),
	 ('Panda wielka','Panda wielka',10),
	 ('Tygrys syberyjski','Tygrys syberyjski',2),
	 ('Zyrafa siatkowana','Safari',5),
	 ('Zebra stepowa','Safari',6),
	 ('Strus czerwonoskory','Safari',8),
	 ('Bawol afrykanski','Safari',5),
	 ('Skocznik antylopi','Safari',10),
	 ('Nosorozec indyjski','Nosorozec indyjski',2),
	 ('Gepard','Gepard',3),
	 ('Lew','Lew',10),
	 ('Hipopotam','Hipopotam',8),
	 ('Slon afrykanski','Slon afrykanski',5),
	 ('Wielblad dwugarbny','Wielblad dwugarbny',5),
	 ('Fenek pustynny','Fenek pustynny',10),
	 ('Likaon pstry','Likaon pstry',15),
	 ('Goryl nizinny','Goryl nizinny',5),
	 ('Lemur katta','Lemury',15),
	 ('Lemur rudy','Lemury',15),
	 ('Lemur wari','Lemury',10),
	 ('Krokodyl rozancowy','Krokodyl rozancowy',2),
	 ('Zolw olbrzymi','Zolw olbrzymi',4),
	 ('Kakadu palmowa','Papuzki',2),
	 ('Zalobnica','Papuzki',2),
	 ('Nimfa','Papuzki',2),
	 ('Zako','Papuzki',2),
	 ('Ara modra','Papuzki',2),
	 ('Ara zoltolica','Papuzki',2),
	 ('Kasnoglowka','Papuzki',2),
	 ('Sekretarz','Sekretarz',1),
	 ('Rybolow zwyczajny','Rybolow zwyczajny',1),
	 ('Jaszczurnik','Jaszczurnik',1),
	 ('Harpia wielka','Harpia wielka',1),
	 ('Orlik malajski','Orlik malajski',1),
	 ('Orzel plamisty','Orzel plamisty',1),
	 ('Plomykowka zwyczajna','Plomykowka zwyczajna',1),
	 ('Plomykowka ziemna','Plomykowka ziemna',1),
	 ('Sowica ciemnolica','Sowica ciemnolica',1),
	 ('Szlaroglowka','Szlaroglowka',1),
	 ('Uszatka zwyczajna','Uszatka zwyczajna',1),
	 ('Syczon krzykliwy','Syczon krzykliwy',1),
	 ('Pirania','Pirania',8),
	 ('Stretwa','Stretwa',1),
	 ('Murena zebra','Murena zebra',1),
	 ('Murena olbrzymia','Murena olbrzymia',1),
	 ('Ognica pstra','Ognica pstra',1),
	 ('Pokolec krolewski','Akwarium1',8),
	 ('Amfiprion plamisty','Akwarium1',8),
	 ('Zebrasoma zolta','Akwarium1',8),
	 ('Gramma loreto','Akwarium1',8),
	 ('Mandaryn wspanialy','Akwarium2',10),
	 ('Pterapogon kauderni','Akwarium2',10),
	 ('Diadema setosum','Akwarium2',4),
	 ('Pensetnik dwuoki','Akwarium3',8),
	 ('Ustnik lunula','Akwarium3',8),
	 ('Motylek czarnopregi','Akwarium3',8),
	 ('Urocaridella','Akwarium3',10),
	 ('Plawikonik','Akwarium4',4),
	 ('Garbik pasiasty','Akwarium4',8),
	 ('Garbik blekitny','Akwarium4',8),
	 ('Ustniczek czarny','Akwarium4',6),
	 ('Ustnik sloneczny','Akwarium4',6),
	 ('Pandka ruda','Pandka ruda',2);

INSERT INTO zwierzeta (imie,nazwa_gatunku,data_urodzenia,plec) VALUES
	 ('Franek','Niedzwiedz brunatny','2002-10-02','M'),
	 ('Lukasz','Ara modra','2001-02-03','M'),
	 ('Nataniel','Kakadu palmowa','1990-05-13','M'),
	 ('Kornelia','Kakadu palmowa','1994-11-06','F'),
	 ('Matylda','Zalobnica','1989-09-21','K'),
	 ('Pistacja','Nimfa','2000-12-13','K'),
	 ('Jonathan','Zako','2000-07-01','M'),
	 ('Erina','Zako','2001-05-23','K'),
	 ('Klaudia','Ara modra','2002-10-02','K'),
	 ('Dorime','Ara zoltolica','1999-10-15','K'),
	 ('Ameno','Ara zoltolica','2000-04-08','M'),
	 ('Pepe','Kasnoglowka','2003-11-25','M'),
	 ('Wojak','Kasnoglowka','2007-04-20','K'),
	 ('Alhaitham','Sekretarz','2003-06-09','M'),
	 ('Ethan','Rybolow zwyczajny','2010-07-02','M'),
	 ('Olesnik','Jaszczurnik','2013-11-22','M'),
	 ('Nalesnik','Harpia wielka','2014-01-16','M'),
	 ('Rei','Orlik malajski','2009-08-12','K'),
	 ('Giorno','Orzel plamisty','2003-05-09','M'),
	 ('Bernardyna','Niedzwiedz brunatny','2005-01-12','K'),
	 ('Marek','Niedzwiedz grizzly','1999-06-12','M'),
	 ('Reksio','Wilk szary','2018-07-24','M'),
	 ('Burek','Wilk szary','2015-01-05','M'),
	 ('Jurek','Wilk szary','2020-12-15','M'),
	 ('Lara','Wilk szary','2017-07-15','K'),
	 ('Malina','Wilk szary','2020-12-15','K'),
	 ('Kalina','Wilk szary','2020-12-15','K'),
	 ('Kometka','Renifer tundrowy','2004-02-10','K'),
	 ('Amorek','Renifer tundrowy','2005-01-03','M'),
	 ('Tancerka','Renifer tundrowy','2007-05-26','K'),
	 ('Pyszalek','Renifer tundrowy','2010-11-28','M'),
	 ('Blyskawiczny','Renifer tundrowy','2014-12-17','M'),
	 ('Fircyk','Renifer tundrowy','2015-03-22','M'),
	 ('Zlosnik','Renifer tundrowy','2020-12-24','M'),
	 ('Profesorek','Renifer tundrowy','2020-12-24','M'),
	 ('Rudolf','Renifer tundrowy','2020-12-24','M'),
	 ('Mucka','Bizon amerykanski','2001-01-19','K'),
	 ('Macku','Bizon amerykanski','2003-06-10','M'),
	 ('Macka','Bizon amerykanski','2005-04-14','K'),
	 ('Bambi','Widlorog amerykanski','2015-02-10','K'),
	 ('Bambolina','Widlorog amerykanski','2019-10-18','K'),
	 ('Rambo','Widlorog amerykanski','2018-05-26','M'),
	 ('Latka','Widlorog amerykanski','2020-01-02','K'),
	 ('Paris','Widlorog amerykanski','2002-03-05','K'),
	 ('Tokio','Makak japonski','2005-11-05','K'),
	 ('Hamamatsu','Makak japonski','2007-09-07','K'),
	 ('Kobe','Makak japonski','2012-10-29','M'),
	 ('Okayama','Makak japonski','2015-06-21','K'),
	 ('Niigata','Makak japonski','2016-08-19','K'),
	 ('Sendai','Makak japonski','2016-08-19','K'),
	 ('Kochi','Makak japonski','2018-02-15','M'),
	 ('Sikoku','Makak japonski','2018-02-15','M'),
	 ('Kirishima','Makak japonski','2020-08-12','K'),
	 ('Kumamoto','Makak japonski','2021-11-23','K'),
	 ('Kungfu','Gepard','2015-07-21','M'),
	 ('Lidka','Gepard','2016-09-25','K'),
	 ('Borowka','Gepard','2022-10-20','K'),
	 ('Rudzielec','Pandka ruda','2017-08-13','M'),
	 ('Radzia','Pandka ruda','2018-10-09','K'),
	 ('Kolad','Tygrys syberyjski','2008-05-10','M'),
	 ('Prazek','Zyrafa siatkowana','2001-11-05','M'),
	 ('Kropka','Zyrafa siatkowana','2006-12-10','K'),
	 ('Uszata','Zyrafa siatkowana','2014-07-05','K'),
	 ('Pasiasta','Zebra stepowa','2008-08-25','K'),
	 ('Gertruda','Zebra stepowa','2010-09-20','K'),
	 ('Hilda','Zebra stepowa','2015-10-12','K'),
	 ('Siweczka','Plomykowka zwyczajna','2010-04-30','K'),
	 ('Ziemek','Plomykowka ziemna','2015-08-31','M'),
	 ('Peorre','Sowica ciemnolica','2007-12-26','M'),
	 ('Szarik','Szlaroglowka','2009-11-19','M'),
	 ('Lilia','Uszatka zwyczajna','2004-09-29','K'),
	 ('Jobin','Syczon krzykliwy','2013-07-07','M'),
	 ('Pi','Pirania','2022-07-31','K'),
	 ('Fi','Pirania','2022-07-31','K'),
	 ('Psi','Pirania','2022-08-21','M'),
	 ('Alfa','Pirania','2022-09-21','M'),
	 ('Sigma','Pirania','2022-09-21','K'),
	 ('Filemon','Stretwa','2021-04-15','M'),
	 ('Zoro','Murena olbrzymia','2021-02-10','M'),
	 ('Nami','Ognica pstra','2021-10-03','K'),
	 ('Nemo','Pokolec krolewski','2022-05-02','M'),
	 ('Emo','Pokolec krolewski','2022-05-02','M'),
	 ('Memo','Pokolec krolewski','2022-05-02','M'),
	 ('Lemo','Pokolec krolewski','2022-05-02','K'),
	 ('Bremo','Pokolec krolewski','2021-07-15','M'),
	 ('Anemo','Pokolec krolewski','2021-10-24','K'),
	 ('Stoodent','Amfiprion plamisty','2022-04-02','M'),
	 ('Debi','Amfiprion plamisty','2022-04-02','K'),
	 ('Peewo','Amfiprion plamisty','2021-09-11','K'),
	 ('Sisi','Zebrasoma zolta','2022-12-01','K'),
	 ('Pipi','Zebrasoma zolta','2022-10-05','K'),
	 ('Kiki','Zebrasoma zolta','2022-12-01','K'),
	 ('Wiki','Zebrasoma zolta','2022-03-16','K'),
	 ('Piki','Zebrasoma zolta','2022-12-01','M'),
	 ('Mimi','Zebrasoma zolta','2022-12-01','K'),
	 ('Lulu','Gramma loreto','2021-12-30','K'),
	 ('Bulu','Gramma loreto','2021-12-30','M'),
	 ('Pulu','Gramma loreto','2021-12-30','M'),
	 ('Man','Mandaryn wspanialy','2020-11-20','M'),
	 ('Daryn','Mandaryn wspanialy','2020-11-20','M'),
	 ('Ka','Mandaryn wspanialy','2020-11-20','M'),
	 ('Hono','Mandaryn wspanialy','2020-11-20','K'),
	 ('Rata','Mandaryn wspanialy','2020-10-17','K'),
	 ('Wata','Mandaryn wspanialy','2020-05-11','K'),
	 ('Pola','Pterapogon kauderni','2022-01-27','K'),
	 ('Lola','Pterapogon kauderni','2022-01-27','K'),
	 ('Kola','Pterapogon kauderni','2022-08-17','K'),
	 ('Mola','Pterapogon kauderni','2022-08-17','K'),
	 ('Stalowa','Pterapogon kauderni','2022-03-14','K'),
	 ('Wola','Pterapogon kauderni','2022-01-27','K'),
	 ('Misa','Diadema setosum','2022-10-13','K'),
	 ('Raito','Diadema setosum','2022-10-13','M'),
	 ('Ryuk','Diadema setosum','2022-10-13','M'),
	 ('Xiangling','Pensetnik dwuoki','2022-05-29','K'),
	 ('Tao','Pensetnik dwuoki','2022-05-29','K'),
	 ('Zhongli','Pensetnik dwuoki','2022-05-29','M'),
	 ('Yunjin','Pensetnik dwuoki','2022-05-29','K'),
	 ('Shenhe','Pensetnik dwuoki','2022-05-29','K'),
	 ('Venti','Ustnik lunula','2022-08-15','M'),
	 ('Barbara','Ustnik lunula','2022-08-15','K'),
	 ('Rosaria','Ustnik lunula','2022-08-15','K'),
	 ('Amber','Ustnik lunula','2022-12-06','K'),
	 ('Bennett','Ustnik lunula','2022-12-06','M'),
	 ('Razor','Ustnik lunula','2022-12-06','M'),
	 ('Monokuma','Motylek czarnopregi','2022-07-25','M'),
	 ('Naegi','Motylek czarnopregi','2022-07-25','M'),
	 ('Aoi','Motylek czarnopregi','2022-07-25','K'),
	 ('Togami','Motylek czarnopregi','2022-02-28','M'),
	 ('Celestia','Motylek czarnopregi','2022-02-28','K'),
	 ('Chihiro','Motylek czarnopregi','2022-02-28','M'),
	 ('Junko','Motylek czarnopregi','2022-02-28','K'),
	 ('Mukuro','Motylek czarnopregi','2022-02-28','K'),
	 ('Toko','Urocaridella','2022-12-09','K'),
	 ('Sayaka','Urocaridella','2022-10-11','K'),
	 ('Hifumi','Urocaridella','2022-12-09','M'),
	 ('Leon','Urocaridella','2022-10-11','M'),
	 ('Mondo','Plawikonik','2022-10-11','M'),
	 ('Hajime','Plawikonik','2022-10-11','M'),
	 ('Akane','Plawikonik','2022-06-01','K'),
	 ('Chiaki','Plawikonik','2022-06-01','K'),
	 ('Ibuki','Garbik pasiasty','2022-10-19','K'),
	 ('Mahiru','Garbik pasiasty','2022-10-19','K'),
	 ('Mikan','Garbik pasiasty','2022-10-19','K'),
	 ('Nagito','Garbik pasiasty','2022-10-19','M'),
	 ('Peko','Garbik pasiasty','2022-12-09','K'),
	 ('Sonia','Garbik pasiasty','2022-12-09','K'),
	 ('Monaca','Garbik blekitny','2022-08-14','K'),
	 ('Komaru','Garbik blekitny','2022-10-11','K'),
	 ('Izuru','Garbik blekitny','2022-08-14','M'),
	 ('Nagisa','Garbik blekitny','2022-10-11','K'),
	 ('Monodam','Slon afrykanski','1990-05-03','M'),
	 ('Monophanie','Slon afrykanski','2000-04-02','F'),
	 ('Monokid','Slon afrykanski','2001-05-31','M'),
	 ('Monosuke','Slon afrykanski','1994-11-19','M'),
	 ('Monotaro','Slon afrykanski','2005-10-24','M'),
	 ('Samira','Wielblad dwugarbny','2003-10-23','F'),
	 ('Thresh','Wielblad dwugarbny','2004-05-25','M'),
	 ('Leona','Fenek pustynny','2017-07-18','F'),
	 ('Diana','Fenek pustynny','2017-07-18','F'),
	 ('Sett','Fenek pustynny','2015-04-25','M'),
	 ('Viego','Fenek pustynny','2020-05-14','M'),
	 ('Garen','Fenek pustynny','2016-11-30','M'),
	 ('Katarina','Fenek pustynny','2017-07-18','K'),
	 ('Vex','Fenek pustynny','2017-07-18','K'),
	 ('Twitch','Fenek pustynny','2020-08-15','M'),
	 ('Kaede','Likaon pstry','2020-06-21','K'),
	 ('Angie','Likaon pstry','2020-06-21','K'),
	 ('Gonta','Likaon pstry','2020-06-21','M'),
	 ('Himiko','Likaon pstry','2018-01-05','K'),
	 ('Keebo','Likaon pstry','2018-01-05','M'),
	 ('Kaito','Likaon pstry','2021-06-15','M'),
	 ('Kirumi','Likaon pstry','2019-09-27','K'),
	 ('Kokichi','Likaon pstry','2019-09-27','K'),
	 ('Korekiyo','Likaon pstry','2019-09-27','M'),
	 ('Maki','Likaon pstry','2017-12-12','K'),
	 ('Shuichi','Likaon pstry','2017-12-18','M'),
	 ('Pedziwiatr','Strus czerwonoskory','2014-03-11','M'),
	 ('Szybciuch','Strus czerwonoskory','2019-05-17','M'),
	 ('Ped','Strus czerwonoskory','2020-11-05','M'),
	 ('Gitka','Strus czerwonoskory','2018-02-28','K'),
	 ('Giga','Bawol afrykanski','2001-05-11','M'),
	 ('Noto','Bawol afrykanski','2005-11-12','K'),
	 ('Skok','Skocznik antylopi','2015-12-30','M'),
	 ('Kok','Skocznik antylopi','2020-11-03','M'),
	 ('Lot','Skocznik antylopi','2020-11-03','M'),
	 ('Mlot','Skocznik antylopi','2020-11-03','M'),
	 ('Lalunia','Skocznik antylopi','2019-10-22','K'),
	 ('Rog','Nosorozec indyjski','2016-05-11','M'),
	 ('Ryk','Lew','2020-11-10','K'),
	 ('Reiko','Lew','2019-01-01','M'),
	 ('Simba','Lew','2020-02-07','M'),
	 ('Mufasa','Lew','2015-06-09','M'),
	 ('Nala','Lew','2020-04-08','K'),
	 ('Skaza','Lew','2012-05-30','M'),
	 ('Zdrada','Lew','2014-08-21','K'),
	 ('Gloria','Hipopotam','2015-08-14','K'),
	 ('Melman','Hipopotam','2012-12-12','M');

INSERT INTO stanowiska(nazwa_stanowiska,wynagrodzenie) VALUES
	 ('Wolontariusz',0),
	 ('Opiekun',3800),
	 ('Dozorca',3700),
	 ('Bileter',3600 ),
	 ('Ochroniarz', 3800 ),
	 ('Weterynarz', 4500 ),
	 ('Ksiegowy', 4200 );

INSERT INTO pracownicy (imie,nazwisko,nazwa_stanowiska,id_strefy,data_zatrudnienia) VALUES
	 ('Klaudia','Kadela','Opiekun',2,'2007-03-21'),
	 ('Jakub','Jawornik','Opiekun',1,'2018-06-12'),
	 ('Wiktoria','Pilak','Bileter',NULL,'2020-12-14'),
	 ('Lukasz','Zwak','Opiekun',3,'2016-12-23'),
	 ('Patryk ','Wawrzacz','Opiekun',4,'2021-09-21'),
	 ('Kamila','Walento','Opiekun',6,'2020-11-05'),
	 ('Witold','Zarzycki','Opiekun',7,'2019-12-16'),
	 ('Magdalena','Skrobala','Dozorca',3,'2021-04-30'),
	 ('Monika','Kloc','Dozorca',4,'2020-01-20'),
	 ('Krzysztof','Malinowski','Dozorca',7,'2018-06-09'),
	 ('Jacek','Sus','Dozorca',6,'2016-08-08'),
	 ('Karol','Wojtyla','Dozorca',1,'2019-05-02'),
	 ('Piotr','Luszcz','Dozorca',2,'2020-02-16'),
	 ('Elzbieta','Druga','Weterynarz',1,'2021-09-21'),
	 ('Elzbieta','Pierwsza','Weterynarz',2,'2022-01-05'),
	 ('Piotr','Skowyrski','Weterynarz',3,'2020-10-14'),
	 ('Tomasz','Dzialowy','Weterynarz',4,'2021-07-07'),
	 ('Magdalena','Maria','Weterynarz',6,'2021-05-04'),
	 ('Marta ','Kaczmaryk','Weterynarz',7,'2020-02-02'),
	 ('Ania','Sim','Bileter',NULL,'2017-09-09'),
	 ('Jozef','Joestar','Ochroniarz',NULL,'2008-10-01'),
	 ('Robert','Spidwagon','Ochroniarz',NULL,'2019-05-03'),
	 ('Jakub','Wodnik','Ksiegowy',NULL,'2016-08-23'),
	 ('Bartlomiej','Sitek','Wolontariusz',NULL,'2017-09-22'),

INSERT INTO bilety (nazwa_biletu,cena) VALUES
	 ('normalny',50),
	 ('ulgowy',35),
	 ('studencki',25),
	 ('grupowy',30);
	 
INSERT INTO historia_wejsc(data_wstepu, nazwa_biletu) VALUES 
	('2022-12-23','ulgowy'),
	('2023-01-26','grupowy'),
	('2023-01-17','normalny'),
	('2022-10-10','grupowy'),
	('2023-01-30','studencki'),
	('2023-01-22','ulgowy'),
	('2022-11-29','studencki'),
	('2023-01-23','grupowy'),
	('2023-01-13','normalny'),
	('2022-11-23','ulgowy'),
	('2023-01-13','normalny'),
	('2023-01-03','normalny'),
	('2022-12-11','grupowy'),
	('2023-01-05','normalny'),
	('2023-01-19','ulgowy'),
	('2022-12-09','studencki'),
	('2023-01-11','ulgowy'),
	('2023-01-08','grupowy');

select przenies_do_lecznicy('Lalunia','2023-02-04','Wymioty');
select przenies_do_lecznicy('Diana','2023-02-04','Ciaza');
select przenies_do_lecznicy('Lulu','2023-02-04', NULL);
select przenies_do_lecznicy('Ameno','2023-02-04','Zlamal reke');
select wypisz_zwierze('Lulu','2023-02-04');
select przenies_do_lecznicy('Lulu','2023-02-04', 'Dziwnie sie zachowuje');