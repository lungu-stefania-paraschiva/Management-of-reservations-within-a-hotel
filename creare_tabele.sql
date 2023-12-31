-- Generated by Oracle SQL Developer Data Modeler 22.2.0.165.1149
--   at:        2023-05-30 20:00:26 EEST
--   site:      Oracle Database 11g
--   type:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE camera (
    nr_camera NUMBER(3) NOT NULL,
    tipul     VARCHAR2(15) NOT NULL,
    pret      NUMBER(5) NOT NULL
)
LOGGING;

ALTER TABLE camera
    ADD CONSTRAINT tip_camera_ck CHECK ( tipul IN ( 'Apartament', 'Dubla', 'Single', 'Tripla' ) );

ALTER TABLE camera ADD CONSTRAINT camera_pk PRIMARY KEY ( nr_camera );

CREATE TABLE rezervare (
    id_rez               NUMBER NOT NULL,
    check_in             DATE NOT NULL,
    check_out            DATE NOT NULL,
    nr_persoane          NUMBER(1) NOT NULL,
    client_cnp_c         NUMBER(13) NOT NULL,
    receptionist_id_angj NUMBER NOT NULL,
    camera_nr_camera     NUMBER(3) NOT NULL
)
LOGGING;

ALTER TABLE rezervare ADD CONSTRAINT rezervare_pk PRIMARY KEY ( id_rez,
                                                                camera_nr_camera );

CREATE OR REPLACE PACKAGE pachet_camera AS
  PROCEDURE insert_camera(
    p_nr_camera       IN camera.nr_camera%TYPE,
    p_tipul           IN camera.tipul%TYPE,
    p_pret            IN camera.pret%TYPE
  );

  PROCEDURE update_camera(
    p_nr_camera       IN camera.nr_camera%TYPE,
    p_pret_nou        IN camera.pret%TYPE
  );

  PROCEDURE delete_camera(
    p_nr_camera IN camera.nr_camera%TYPE
  );

  PROCEDURE afisare_camere_indisponibile;
  
  FUNCTION get_tip_camera(p_nr_camera IN NUMBER) RETURN camera.tipul%type;

END pachet_camera;
/

CREATE OR REPLACE PACKAGE BODY pachet_camera AS
    -----------------------------------------
    ----------------PROCEDURI----------------
    -----------------------------------------
	
	----------------INSERT----------------
    PROCEDURE insert_camera(
        p_nr_camera       IN camera.nr_camera%TYPE,
        p_tipul           IN camera.tipul%TYPE,
        p_pret            IN camera.pret%TYPE
    )
    AS
    BEGIN
        INSERT INTO camera VALUES (p_nr_camera, p_tipul, p_pret);
        
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(-20001, 'Camera cu numarul specificat există deja în baza de date.');
			WHEN OTHERS THEN
				RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscută: ' || SQLERRM);
    END insert_camera;

    ----------------UPDATE----------------
    PROCEDURE update_camera(
        p_nr_camera       IN camera.nr_camera%TYPE,
        p_pret_nou        IN camera.pret%TYPE
    )
    AS
    BEGIN
        UPDATE camera
        SET pret = p_pret_nou
        WHERE nr_camera = p_nr_camera;
        
        IF SQL%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nu există nicio camera cu numarul specificat în baza de date.');
        END IF;
    END update_camera;

    ----------------DELETE----------------
    PROCEDURE delete_camera(
        p_nr_camera IN camera.nr_camera%TYPE
    )
    AS
    BEGIN
        DELETE FROM camera
        WHERE nr_camera = p_nr_camera;
        
        IF SQL%NOTFOUND THEN
          RAISE_APPLICATION_ERROR(-20003, 'Nu exista nicio camera cu numarul specificat in baza de date.');
        END IF;
    
    END delete_camera;
	
	----------------AFISARI----------------
	PROCEDURE afisare_camere_indisponibile IS
	BEGIN
	  FOR c1_record IN (SELECT c.nr_camera AS camera, r.check_in AS checkIn, r.check_out AS checkOut
						FROM camera c, rezervare r
						WHERE c.nr_camera = r.camera_nr_camera) LOOP
		dbms_output.put_line('Camera: ' || c1_record.camera || ' Perioada indisponibila: ' || c1_record.checkIn || ' - ' || c1_record.checkOut);
	  END LOOP;
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('Nu exista camere!');
	  WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
	END afisare_camere_indisponibile;


    FUNCTION get_tip_camera(p_nr_camera IN NUMBER) RETURN camera.tipul%type
	IS
		tip_camera camera.tipul%type;
	BEGIN
		SELECT tipul INTO tip_camera
		FROM camera
		WHERE nr_camera = p_nr_camera; 

		RETURN tip_camera;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20003, 'Nu existAa nicio camera cu numarul specificat in baza de date.');
	END;
	
END pachet_camera;
/

CREATE TABLE client (
    cnp_c   NUMBER(13) NOT NULL,
    nume    VARCHAR2(30) NOT NULL,
    prenume VARCHAR2(30) NOT NULL,
    telefon NUMBER(10) NOT NULL,
    email   VARCHAR2(50) NOT NULL,
    adresa  VARCHAR2(100) NOT NULL,
    varsta  NUMBER(3) NOT NULL
)
LOGGING;

ALTER TABLE client
    ADD CHECK ( length(nume) >= 2 );

ALTER TABLE client
    ADD CHECK ( length(nume) >= 2 );

ALTER TABLE client
    ADD CONSTRAINT email_c_ck CHECK ( REGEXP_LIKE ( email,
                                                    '[a-z0-9._%-]+@[a-z0-9._%-]+\.[a-z]{2,4}' ) );

ALTER TABLE client ADD CHECK ( length(adresa) > 10 );

ALTER TABLE client ADD CONSTRAINT client_pk PRIMARY KEY ( cnp_c );

ALTER TABLE client ADD CONSTRAINT client_telefon_un UNIQUE ( telefon );

ALTER TABLE client ADD CONSTRAINT client_email_un UNIQUE ( email );

CREATE TABLE factura (
    id_fact                    NUMBER NOT NULL,
    data_facturarii            DATE NOT NULL,
    suma_totala                NUMBER(10) NOT NULL,
    avans                      NUMBER(10) NOT NULL,
    cif                        VARCHAR2(12) NOT NULL,
    metoda_de_plata            VARCHAR2(25) NOT NULL,
    rezervare_id_rez           NUMBER NOT NULL,
    rezervare_camera_nr_camera NUMBER(3) NOT NULL
)
LOGGING;

ALTER TABLE factura ADD CONSTRAINT suma_totala_ck CHECK ( suma_totala > 0 );

ALTER TABLE factura ADD CONSTRAINT avans_ck CHECK ( avans >= 0 );

ALTER TABLE factura
    ADD CONSTRAINT cif_ck CHECK ( REGEXP_LIKE ( cif,
                                                '^RO[0-9]{9}[A-Z]$' ) );

ALTER TABLE factura
    ADD CONSTRAINT metoda_plata_ck CHECK ( metoda_de_plata IN ( 'Bonuri', 'Card', 'Cash' ) );

COMMENT ON COLUMN factura.cif IS
    'Codul de identificare fiscală';

CREATE UNIQUE INDEX factura__idx ON
    factura (
        rezervare_id_rez
    ASC,
        rezervare_camera_nr_camera
    ASC )
        LOGGING;

ALTER TABLE factura ADD CONSTRAINT factura_pk PRIMARY KEY ( id_fact );

CREATE OR REPLACE PACKAGE pachet_client AS
  PROCEDURE insert_client(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_nume    IN client.nume%TYPE,
    p_prenume IN client.prenume%TYPE,
    p_telefon IN client.telefon%TYPE,
    p_email   IN client.email%TYPE,
    p_adresa  IN client.adresa%TYPE,
    p_varsta  IN client.varsta%TYPE
  );

   PROCEDURE update_client_telefon(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_telefon IN client.telefon%TYPE
  );

  PROCEDURE update_client_email(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_email   IN client.email%TYPE
  );

  PROCEDURE update_client_nume(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_nume    IN client.nume%TYPE
  );

  PROCEDURE update_client_adresa(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_adresa  IN client.adresa%TYPE
  );

  PROCEDURE delete_client(
    p_cnp_c IN client.cnp_c%TYPE
  );
  
  PROCEDURE afisare_rezervari_client_perioada(v_cnp IN client.cnp_c%TYPE);
  
  FUNCTION has_reservations(p_cnp IN client.cnp_c%TYPE) RETURN BOOLEAN;
  

END pachet_client;
/

CREATE OR REPLACE PACKAGE BODY pachet_client AS
    ----------------INSERT----------------
  PROCEDURE insert_client(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_nume    IN client.nume%TYPE,
    p_prenume IN client.prenume%TYPE,
    p_telefon IN client.telefon%TYPE,
    p_email   IN client.email%TYPE,
    p_adresa  IN client.adresa%TYPE,
    p_varsta  IN client.varsta%TYPE
  )
  AS
  BEGIN
    INSERT INTO client (cnp_c, nume, prenume, telefon, email, adresa, varsta)
    VALUES (p_cnp_c, p_nume, p_prenume, p_telefon, p_email, p_adresa, p_varsta);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Clientul cu CNP-ul specificat există deja în baza de date.');
	WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscutÄ?: ' || SQLERRM);
  END insert_client;

    ----------------UPDATE TELEFON----------------
   PROCEDURE update_client_telefon(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_telefon IN client.telefon%TYPE
  )
  AS
  BEGIN
    UPDATE client
    SET telefon = p_telefon
    WHERE cnp_c = p_cnp_c;
    IF SQL%NOTFOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
    END IF;
  END update_client_telefon;

 ----------------UPDATE EMAIL----------------
  PROCEDURE update_client_email(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_email   IN client.email%TYPE
  )
  AS
  BEGIN
    UPDATE client
    SET email = p_email
    WHERE cnp_c = p_cnp_c;
    IF SQL%NOTFOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
    END IF;
  END update_client_email;

 ----------------UPDATE NUME----------------
  PROCEDURE update_client_nume(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_nume    IN client.nume%TYPE
  )
  AS
  BEGIN
    UPDATE client
    SET nume = p_nume
    WHERE cnp_c = p_cnp_c;
    IF SQL%NOTFOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
    END IF;
  END update_client_nume;

 ----------------UPDATE ADRESA----------------
  PROCEDURE update_client_adresa(
    p_cnp_c   IN client.cnp_c%TYPE,
    p_adresa  IN client.adresa%TYPE
  )
  AS
  BEGIN
    UPDATE client
    SET adresa = p_adresa
    WHERE cnp_c = p_cnp_c;
    IF SQL%NOTFOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
    END IF;
  END update_client_adresa;


 ----------------DELETE----------------
  PROCEDURE delete_client(
    p_cnp_c IN client.cnp_c%TYPE
  )
  AS
  BEGIN
    DELETE FROM client
    WHERE cnp_c = p_cnp_c;
    IF SQL%NOTFOUND THEN
      RAISE_APPLICATION_ERROR(-20003, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20004, 'A apărut o eroare la ?tergerea clientului.');
  END delete_client;
  
----------------AFISARI----------------
	PROCEDURE afisare_rezervari_client_perioada(v_cnp IN client.cnp_c%TYPE) IS
	  TYPE client_rez_typ IS RECORD (nume client.nume%TYPE,
										prenume client.prenume%TYPE,
										check_in rezervare.check_in%TYPE,
										check_out rezervare.check_out%TYPE,
										suma_totala factura.suma_totala%TYPE);
		
	  TYPE client_rez IS REF CURSOR RETURN client_rez_typ;
	  vc_client client_rez;
	  rc_afis_client client_rez_typ;
	  v_count NUMBER :=0;
	BEGIN
		-- Verificare existenta CNP-ului în tabela client
	  SELECT COUNT(*) INTO v_count
	  FROM client
	  WHERE cnp_c = v_cnp;
	  
	  IF v_count > 0 THEN
		dbms_output.put_line('Rezervarile facute de client: ');
		  OPEN vc_client FOR
				SELECT c.nume, c.prenume, r.check_in, r.check_out, f.suma_totala
				FROM client c, rezervare r, factura f
				WHERE c.cnp_c = v_cnp AND c.cnp_c = r.client_cnp_c 
					AND r.id_rez = f.rezervare_id_rez;
				
		  LOOP
			FETCH vc_client INTO rc_afis_client;
			EXIT WHEN (vc_client%NOTFOUND);
			dbms_output.put_line('Nume: ' || rc_afis_client.nume || ' Prenume: ' || rc_afis_client.prenume || ' Check-in: ' 
					|| rc_afis_client.check_in || ' Check-out: ' || rc_afis_client.check_out 
					|| ' Suma totala : ' || rc_afis_client.suma_totala );
		  END LOOP;
		  CLOSE vc_client;
	  ELSE
		RAISE_APPLICATION_ERROR(-20005, 'Nu există niciun client cu CNP-ul specificat în baza de date.');
	  END IF;

	EXCEPTION
	  WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
	END afisare_rezervari_client_perioada;
	
	-----------------------------------------
    ----------------FUNCTII----------------
    -----------------------------------------
	
	FUNCTION has_reservations(p_cnp IN client.cnp_c%TYPE) RETURN BOOLEAN IS
		v_count NUMBER;
	BEGIN
		SELECT COUNT(*)
		INTO v_count
		FROM rezervare
		WHERE client_cnp_c = p_cnp;

		IF v_count > 0 THEN
			RETURN TRUE; -- Clientul are rezervări
		ELSE
			RETURN FALSE; -- Clientul nu are rezervări
		END IF;
	END has_reservations;


END pachet_client;
/

CREATE OR REPLACE PACKAGE pachet_factura IS
  PROCEDURE insert_factura (
    p_id_fact          IN factura.id_fact%TYPE,
    p_data_facturarii  IN factura.data_facturarii%TYPE,
    p_cif              IN factura.cif%TYPE,
    p_metoda_de_plata  IN factura.metoda_de_plata%TYPE,
    p_rezervare_id_rez IN factura.rezervare_id_rez%TYPE
  );

  PROCEDURE update_metoda_plata (
    p_id_fact         IN factura.id_fact%TYPE,
    p_metoda_de_plata IN factura.metoda_de_plata%TYPE
  );
  
  PROCEDURE delete_factura (
    p_id_fact IN factura.id_fact%TYPE
  );
  
   PROCEDURE afisare_facturi;

END pachet_factura;
/

CREATE OR REPLACE PACKAGE BODY pachet_factura IS
  PROCEDURE insert_factura (
    p_id_fact          IN factura.id_fact%TYPE,
    p_data_facturarii  IN factura.data_facturarii%TYPE,
    p_cif              IN factura.cif%TYPE,
    p_metoda_de_plata  IN factura.metoda_de_plata%TYPE,
    p_rezervare_id_rez IN factura.rezervare_id_rez%TYPE
  ) IS
  
    v_check_in rezervare.check_in%type;
    v_check_out rezervare.check_out%type;
    v_rezervare_camera_nr_camera factura.rezervare_camera_nr_camera%TYPE;
    v_diferenta_zile NUMBER := 0;
    v_suma_totala factura.suma_totala%type := 0;
    v_pret_camera camera.pret%type;
    v_avans factura.avans%type := 0;
  BEGIN
  
  --selecteaza nr camerei si perioada rezervata dupa id-ul rezervarii
    SELECT r.camera_nr_camera, r.check_in, r.check_out 
    INTO v_rezervare_camera_nr_camera, v_check_in, v_check_out
    FROM rezervare r 
    WHERE id_rez = p_rezervare_id_rez;
    
    --selecteaza pretului camerei alese
    SELECT pret INTO v_pret_camera FROM camera WHERE nr_camera = v_rezervare_camera_nr_camera;
    
    --calculeaza diferenta
    v_diferenta_zile := FLOOR(v_check_out - v_check_in); 
    v_suma_totala := v_diferenta_zile * v_pret_camera;
    v_avans := v_suma_totala * 0.20;
    
    INSERT INTO factura VALUES (
      p_id_fact,
      p_data_facturarii,
      v_suma_totala,
      v_avans,
      p_cif,
      p_metoda_de_plata,
      p_rezervare_id_rez,
      v_rezervare_camera_nr_camera
    );
    
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20000, 'Factura cu id-ul specificat există deja în baza de date.');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Eroare la inserarea facturii: ' || SQLERRM);
  END insert_factura;
  
  PROCEDURE update_metoda_plata (
    p_id_fact          IN factura.id_fact%TYPE,
    p_metoda_de_plata  IN factura.metoda_de_plata%TYPE
  ) IS
  BEGIN
    UPDATE factura
    SET metoda_de_plata = p_metoda_de_plata
    WHERE id_fact = p_id_fact;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Nu exisa factura cu id-ul specificat: ' || p_id_fact);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Eroare în actualizarea metodei de plata: ' || SQLERRM);
  END update_metoda_plata;
    
    PROCEDURE delete_factura (
        p_id_fact IN factura.id_fact%TYPE
    ) IS
    BEGIN
        DELETE FROM factura WHERE id_fact = p_id_fact;
        
        IF SQL%ROWCOUNT = 0 THEN
          RAISE_APPLICATION_ERROR(-20002, 'Nu exista factura cu id-ul: ' || p_id_fact);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Eroare in stergerea facturii: ' || SQLERRM);
    END delete_factura;

    ----------------AFISARI----------------
    PROCEDURE afisare_facturi IS
    BEGIN
      DBMS_OUTPUT.PUT_LINE('Facturi existente:');
      
      FOR factura_rec IN (
        SELECT f.id_fact, f.data_facturarii, f.cif, f.metoda_de_plata,
               r.check_in, r.check_out, c.nume, c.prenume
        FROM factura f
        INNER JOIN rezervare r ON f.rezervare_id_rez = r.id_rez
        INNER JOIN client c ON r.client_cnp_c = c.cnp_c
      ) LOOP
        DBMS_OUTPUT.PUT_LINE('ID Factura: ' || factura_rec.id_fact);
        DBMS_OUTPUT.PUT_LINE('Data facturarii: ' || factura_rec.data_facturarii);
        DBMS_OUTPUT.PUT_LINE('CIF: ' || factura_rec.cif);
        DBMS_OUTPUT.PUT_LINE('Metoda de plata: ' || factura_rec.metoda_de_plata);
        DBMS_OUTPUT.PUT_LINE('Check-in: ' || factura_rec.check_in);
        DBMS_OUTPUT.PUT_LINE('Check-out: ' || factura_rec.check_out);
        DBMS_OUTPUT.PUT_LINE('Nume Client: ' || factura_rec.nume);
        DBMS_OUTPUT.PUT_LINE('Prenume Client: ' || factura_rec.prenume);
        DBMS_OUTPUT.PUT_LINE('------------------------');
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
    END afisare_facturi;

END pachet_factura;
/

CREATE TABLE receptionist (
    id_angj        NUMBER NOT NULL,
    cnp_a          NUMBER(13) NOT NULL,
    nume           VARCHAR2(30) NOT NULL,
    prenume        VARCHAR2(30) NOT NULL,
    adresa         VARCHAR2(100) NOT NULL,
    telefon        NUMBER(10) NOT NULL,
    salar          NUMBER(5) NOT NULL,
    data_angajarii DATE NOT NULL
)
LOGGING;

ALTER TABLE receptionist
    ADD CHECK ( length(nume) >= 2 );

ALTER TABLE receptionist
    ADD CHECK ( length(nume) >= 2 );

ALTER TABLE receptionist ADD CHECK ( length(adresa) > 10 );

ALTER TABLE receptionist ADD CONSTRAINT salar_ck CHECK ( salar > 500 );

ALTER TABLE receptionist ADD CONSTRAINT receptionist_pk PRIMARY KEY ( id_angj );

ALTER TABLE receptionist ADD CONSTRAINT receptionist_telefon_un UNIQUE ( telefon );

CREATE OR REPLACE PACKAGE pachet_receptionist IS

  PROCEDURE insert_receptionist(
    p_id_angj        IN receptionist.id_angj%TYPE,
    p_cnp_a          IN receptionist.cnp_a%TYPE,
    p_nume           IN receptionist.nume%TYPE,
    p_prenume        IN receptionist.prenume%TYPE,
    p_adresa         IN receptionist.adresa%TYPE,
    p_telefon        IN receptionist.telefon%TYPE,
    p_salar          IN receptionist.salar%TYPE,
    p_data_angajarii IN receptionist.data_angajarii%TYPE
  );
    
  PROCEDURE update_salar_receptionist(
    p_id_angj  IN receptionist.id_angj%TYPE,
    p_salar    IN receptionist.salar%TYPE
  );

  PROCEDURE update_adresa_receptionist(
    p_id_angj IN receptionist.id_angj%TYPE,
    p_adresa   IN receptionist.adresa%TYPE
  );

  PROCEDURE update_telefon_receptionist(
    p_id_angj   IN receptionist.id_angj%TYPE,
    p_telefon   IN receptionist.telefon%TYPE
  );

  PROCEDURE delete_receptionist(p_id_angj IN receptionist.id_angj%TYPE);
END pachet_receptionist;
/

CREATE OR REPLACE PACKAGE BODY pachet_receptionist IS
    -----------------------------------------
    ----------------PROCEDURI----------------
    -----------------------------------------
    -----------------------------------------
    -----------------------------------------
    
    ----------------INSERT----------------
  PROCEDURE insert_receptionist(
    p_id_angj        IN receptionist.id_angj%TYPE,
    p_cnp_a          IN receptionist.cnp_a%TYPE,
    p_nume           IN receptionist.nume%TYPE,
    p_prenume        IN receptionist.prenume%TYPE,
    p_adresa         IN receptionist.adresa%TYPE,
    p_telefon        IN receptionist.telefon%TYPE,
    p_salar          IN receptionist.salar%TYPE,
    p_data_angajarii IN receptionist.data_angajarii%TYPE
  ) IS
  BEGIN
    INSERT INTO receptionist VALUES (
      p_id_angj,
      p_cnp_a,
      p_nume,
      p_prenume,
      p_adresa,
      p_telefon,
      p_salar,
      p_data_angajarii
    );
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002, 'Eroare la inserarea receptionistului. ' || SQLERRM);
  END insert_receptionist;
    
      ----------------UPDATE----------------
      --SALAR
    PROCEDURE update_salar_receptionist(
        p_id_angj  IN receptionist.id_angj%TYPE,
        p_salar    IN receptionist.salar%TYPE
      ) IS
      BEGIN
        UPDATE receptionist
        SET salar = p_salar
        WHERE id_angj = p_id_angj;
    
        IF SQL%ROWCOUNT = 0 THEN
          RAISE_APPLICATION_ERROR(-20002, 'Receptionistul cu ID-ul ' || p_id_angj || ' nu este gasit.');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002, 'Eroare la actualizarea salariului. ' || SQLERRM);
    END update_salar_receptionist;

    --ADRESA
  PROCEDURE update_adresa_receptionist(
    p_id_angj  IN receptionist.id_angj%TYPE,
    p_adresa   IN receptionist.adresa%TYPE
  ) IS
  BEGIN
    UPDATE receptionist
    SET adresa = p_adresa
    WHERE id_angj = p_id_angj;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Receptionistul cu ID-ul ' || p_id_angj || ' nu este gasit.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002, 'Eroare la actualizarea adresei. ' || SQLERRM);
  END update_adresa_receptionist;

    --TELEFON
  PROCEDURE update_telefon_receptionist(
    p_id_angj  IN receptionist.id_angj%TYPE,
    p_telefon  IN receptionist.telefon%TYPE
  ) IS
  BEGIN
    UPDATE receptionist
    SET telefon = p_telefon
    WHERE id_angj = p_id_angj;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Receptionistul cu ID-ul ' || p_id_angj || ' nu este gasit.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002, 'Eroare la actualizarea numarului de telefon. ' || SQLERRM);
  END update_telefon_receptionist;
    
     ----------------DELETE----------------
    PROCEDURE delete_receptionist(p_id_angj IN receptionist.id_angj%TYPE) IS
        BEGIN
            DELETE FROM receptionist WHERE id_angj = p_id_angj;
            IF SQL%ROWCOUNT = 0 THEN
                RAISE_APPLICATION_ERROR(-20002, 'Receptionistul cu ID-ul ' || p_id_angj || ' nu este gasit.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20002, 'Eroare la stergerea receptionistului. ' || SQLERRM);
    END delete_receptionist;
END pachet_receptionist;
/

CREATE OR REPLACE PACKAGE pachet_rezervare IS

    PROCEDURE insert_rezervare(
        p_id_rez               IN rezervare.id_rez%TYPE,
        p_check_in             IN rezervare.check_in%TYPE,
        p_check_out            IN rezervare.check_out%TYPE,
        p_nr_persoane          IN rezervare.nr_persoane%TYPE,
        p_client_cnp_c         IN rezervare.client_cnp_c%TYPE,
        p_receptionist_id_angj IN rezervare.receptionist_id_angj%TYPE
    );

    PROCEDURE update_rezervare_check_in(
        p_id_rez               IN rezervare.id_rez%TYPE,
        p_check_in             IN rezervare.check_in%TYPE,
		p_cnp_c 			   IN rezervare.client_cnp_c%type
    );
    
    PROCEDURE update_rezervare_check_out(
        p_id_rez               IN rezervare.id_rez%TYPE,
        p_check_out             IN rezervare.check_out%TYPE,
		p_cnp_c 			   IN rezervare.client_cnp_c%type
    );
    
    PROCEDURE delete_rezervare(
        p_id_rez IN rezervare.id_rez%TYPE
     );
	 
	PROCEDURE afisare_rezervari_client_suma;

    FUNCTION get_camera_disponibile(
        p_tipul_camerei     IN camera.tipul%type,
        p_check_in          IN rezervare.check_in%type,
        p_check_out         IN rezervare.check_out%type) RETURN camera.nr_camera%type;

END pachet_rezervare;
/

CREATE OR REPLACE PACKAGE BODY pachet_rezervare IS
    -----------------------------------------
    ----------------PROCEDURI----------------
    -----------------------------------------
    -----------------------------------------
    -----------------------------------------
    
    ----------------INSERT----------------
    PROCEDURE insert_rezervare(
    p_id_rez               IN rezervare.id_rez%TYPE,
    p_check_in             IN rezervare.check_in%TYPE,
    p_check_out            IN rezervare.check_out%TYPE,
    p_nr_persoane          IN rezervare.nr_persoane%TYPE,
    p_client_cnp_c         IN rezervare.client_cnp_c%TYPE,
    p_receptionist_id_angj IN rezervare.receptionist_id_angj%TYPE
    ) IS
        v_tip_camera camera.tipul%type;
        v_nr_camera_disponibila camera.nr_camera%TYPE;
    BEGIN
        
        IF p_nr_persoane > 4 THEN
            RAISE_APPLICATION_ERROR(-20000,'Numarul de persoane ' || p_nr_persoane || ' este prea mare pentru o singura camera!');
        ELSE
            IF p_nr_persoane = 1 THEN
                v_tip_camera := 'Single';
            ELSIF p_nr_persoane = 2 THEN
                v_tip_camera := 'Dubla';
            ELSIF p_nr_persoane = 3 THEN
                v_tip_camera := 'Tripla';
            ELSIF p_nr_persoane = 4 THEN
                v_tip_camera := 'Apartament';
            END IF;
           
           v_nr_camera_disponibila := get_camera_disponibile(v_tip_camera, p_check_in, p_check_out);
           
            IF v_nr_camera_disponibila IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'Nu sunt camere disponibile de tipul ' || v_tip_camera || ' in perioada ' || p_check_in || ' - ' || p_check_out || '!');
            ELSE
                INSERT INTO rezervare VALUES (p_id_rez, p_check_in, p_check_out, p_nr_persoane, p_client_cnp_c, p_receptionist_id_angj, v_nr_camera_disponibila);
            END IF;
        END IF;
    
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20001, 'Rezervarea cu ID-ul specificat există deja în baza de date.');
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscută: ' || SQLERRM);
    END insert_rezervare;

    ----------------UPDATE----------------
    ---CHECK-IN---
    PROCEDURE update_rezervare_check_in(
		p_id_rez    IN rezervare.id_rez%TYPE,
		p_check_in  IN rezervare.check_in%TYPE,
		p_cnp_c     IN rezervare.client_cnp_c%TYPE
	) IS
		v_cnp rezervare.client_cnp_c%TYPE;
	BEGIN
		-- Verificați dacă CNP-ul dat este diferit de cel din rezervare
		SELECT client_cnp_c INTO v_cnp
		FROM rezervare
		WHERE id_rez = p_id_rez;
		
		IF v_cnp <> p_cnp_c THEN
			RAISE_APPLICATION_ERROR(-20003, 'CNP-ul specificat nu corespunde CNP-ului asociat rezervării.');
		END IF;
		
		-- Actualizați rezervarea
		UPDATE rezervare
		SET check_in = p_check_in
		WHERE id_rez = p_id_rez AND client_cnp_c = p_cnp_c;

		IF SQL%NOTFOUND THEN
			RAISE_APPLICATION_ERROR(-20002, 'Nu există nicio rezervare cu ID-ul specificat în baza de date.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscută: ' || SQLERRM);
	END update_rezervare_check_in;


    ---CHECK-OUT---
    PROCEDURE update_rezervare_check_out(
        p_id_rez               IN rezervare.id_rez%TYPE,
        p_check_out             IN rezervare.check_out%TYPE,
		p_cnp_c 			   IN rezervare.client_cnp_c%type
    ) IS
		v_cnp rezervare.client_cnp_c%TYPE;
		v_nr_camera_disponibila camera.nr_camera%TYPE;
    BEGIN
		-- Verificați dacă CNP-ul dat este diferit de cel din rezervare
		SELECT client_cnp_c INTO v_cnp
		FROM rezervare
		WHERE id_rez = p_id_rez;
		
		IF v_cnp <> p_cnp_c THEN
			RAISE_APPLICATION_ERROR(-20003, 'CNP-ul specificat nu corespunde CNP-ului asociat rezervării.');
		END IF;
		
		v_nr_camera_disponibila := get_camera_disponibile(v_tip_camera, p_check_in, p_check_out);
		IF v_nr_camera_disponibila IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'Nu sunt camere disponibile de tipul ' || v_tip_camera || ' in perioada ' || p_check_in || ' - ' || p_check_out || '!');
            ELSE
                 UPDATE rezervare r SET r.check_out = p_check_out WHERE r.id_rez = p_id_rez AND r.client_cnp_c = p_cnp_c;
            END IF;
       
		
        IF SQL%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nu există nicio rezervare cu ID-ul specificat în baza de date.');
          END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscută: ' || SQLERRM);
    END update_rezervare_check_out;
    
    ----------------DELETE----------------
    PROCEDURE delete_rezervare(p_id_rez IN rezervare.id_rez%TYPE) IS
    BEGIN
      DELETE FROM rezervare
      WHERE id_rez = p_id_rez;
    
      IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nu există nicio rezervare cu ID-ul specificat în baza de date.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Eroare necunoscută: ' || SQLERRM);
    END delete_rezervare;
	
	----------------AFISARI----------------
	PROCEDURE afisare_rezervari_client_suma IS
	BEGIN
	  FOR c1_record IN (SELECT c.cnp_c AS cnp, c.nume AS nume, c.prenume AS prenume, r.id_rez AS idR, sum(f.suma_totala) AS suma
						FROM client c, rezervare r, factura f
						WHERE c.cnp_c = r.client_cnp_c AND r.id_rez = f.rezervare_id_rez
						GROUP BY c.cnp_c, c.nume, c.prenume, r.id_rez) LOOP
		dbms_output.put_line('ID rezervare: ' || c1_record.idR || ' Nume: ' || c1_record.nume || ' ' || c1_record.prenume || ' Suma totala: ' || c1_record.suma);
	  END LOOP;
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('Nu exista rezervari!');
	  WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
	END afisare_rezervari_client_suma;
    
    
    -----------------------------------------
    ----------------FUNCTII----------------
    -----------------------------------------
    
    --Returneaza camera disponibila conform tipului dat si perioadei de rezervare
    FUNCTION get_camera_disponibile(
        p_tipul_camerei     IN camera.tipul%type,
        p_check_in          IN rezervare.check_in%type,
        p_check_out         IN rezervare.check_out%type) RETURN camera.nr_camera%type IS
    
        v_nr_camera camera.nr_camera%type;
    
    BEGIN
        SELECT c.nr_camera
        INTO v_nr_camera
        FROM camera c
        WHERE c.tipul = p_tipul_camerei
          AND NOT EXISTS (
            SELECT 1
            FROM rezervare r
            WHERE r.check_in <= p_check_out
              AND r.check_out >= p_check_in
              AND r.camera_nr_camera = c.nr_camera
          )
          FETCH FIRST 1 ROW ONLY;
          
    
        RETURN v_nr_camera;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    
    END get_camera_disponibile;

        
END pachet_rezervare;
/

ALTER TABLE factura
    ADD CONSTRAINT factura_rezervare_fk FOREIGN KEY ( rezervare_id_rez,
                                                      rezervare_camera_nr_camera )
        REFERENCES rezervare ( id_rez,
                               camera_nr_camera )
    NOT DEFERRABLE;

ALTER TABLE rezervare
    ADD CONSTRAINT rezervare_camera_fk FOREIGN KEY ( camera_nr_camera )
        REFERENCES camera ( nr_camera )
    NOT DEFERRABLE;

ALTER TABLE rezervare
    ADD CONSTRAINT rezervare_client_fk FOREIGN KEY ( client_cnp_c )
        REFERENCES client ( cnp_c )
    NOT DEFERRABLE;

ALTER TABLE rezervare
    ADD CONSTRAINT rezervare_receptionist_fk FOREIGN KEY ( receptionist_id_angj )
        REFERENCES receptionist ( id_angj )
    NOT DEFERRABLE;

CREATE OR REPLACE TRIGGER trigger_check_dates 
    BEFORE INSERT OR UPDATE ON Rezervare 
    FOR EACH ROW 
DECLARE
BEGIN
    IF :NEW.check_in < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Data de check-in trebuie să fie în viitor.');
    ELSIF :NEW.check_out < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Data de check-out trebuie să fie în viitor.');
    ELSIF :NEW.check_in >= :NEW.check_out THEN
        RAISE_APPLICATION_ERROR(-20002, 'Data de check-in trebuie să fie înainte de data de check-out.');
    END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_check_email 
    BEFORE INSERT OR UPDATE OF email ON Client 
    FOR EACH ROW 
DECLARE
BEGIN
    IF REGEXP_LIKE(:NEW.email, '[a-z0-9._%-]+@[a-z0-9._%-]+\.[a-z]{2,4}') = FALSE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Adresa de email nu are un format valid!');
    END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_check_nr_pers 
    BEFORE INSERT OR UPDATE OF nr_persoane ON Rezervare 
    FOR EACH ROW 
DECLARE
BEGIN
    IF :NEW.nr_persoane > 4 THEN
		RAISE_APPLICATION_ERROR(-20000, 'Numarul de persoane ' || :NEW.nr_persoane || ' este prea mare pentru o singura camera!');
	END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_check_tip_camera 
    BEFORE INSERT ON Camera 
    FOR EACH ROW 
DECLARE
BEGIN
    IF :NEW.tipul NOT IN ('Dubla', 'Single', 'Tripla', 'Apartament') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Tipul camerei nu este valid. Tipuri valide: dubla, single, tripla, apartament.');
    END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_check_varsta 
    BEFORE INSERT OR UPDATE OF varsta ON Client 
    FOR EACH ROW 
DECLARE
BEGIN
    IF :NEW.varsta < 18 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Clientul trebuie sa fie major!');
	END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_salar_receptionist 
    BEFORE UPDATE OF salar ON Receptionist 
    FOR EACH ROW 
DECLARE
  v_salar_anterior receptionist.salar%TYPE;
BEGIN
  -- Verificãm salariul anterior
  SELECT salar INTO v_salar_anterior
  FROM receptionist
  WHERE id_angj = :NEW.id_angj;

  IF :NEW.salar < v_salar_anterior THEN
    -- Ridicãm o eroare în cazul în care salariul nou este mai mic decât cel existent
    RAISE_APPLICATION_ERROR(-20003, 'Nu se poate introduce un salariu mai mic decât cel existent.');
  END IF;
END; 
/

CREATE OR REPLACE TRIGGER trigger_update_suma_totala 
    AFTER UPDATE ON Camera 
    FOR EACH ROW 
DECLARE
  v_rezervare_id_rez factura.rezervare_id_rez%TYPE;
  v_suma_totala factura.suma_totala%TYPE;
BEGIN
    -- Obtineti ID-ul rezervãrii asociate camerei
    SELECT rezervare_id_rez INTO v_rezervare_id_rez
    FROM factura
    WHERE rezervare_camera_nr_camera = :new.nr_camera
    AND ROWNUM = 1;
    
  -- Calculeazã noua sumã totalã
  SELECT FLOOR((r.check_out - r.check_in) / 1) * :new.pret INTO v_suma_totala
  FROM rezervare r
  WHERE r.id_rez = v_rezervare_id_rez;
    
  -- Actualizeazã suma totalã pe factura
  UPDATE factura
  SET suma_totala = v_suma_totala
  WHERE rezervare_camera_nr_camera = :new.nr_camera;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL; -- Nu existã o rezervare asociatã camerei sau factura nu existã
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20004, 'Eroare în actualizarea sumei totale: ' || SQLERRM);
END; 
/



-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                             5
-- CREATE INDEX                             1
-- ALTER TABLE                             25
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           5
-- CREATE PACKAGE BODY                      1
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           7
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   0
-- WARNINGS                                 0
