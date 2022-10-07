
DROP FUNCTION IF EXISTS trans.trans_cycles_bk_process CASCADE;
CREATE FUNCTION trans.trans_cycles_bk_process() RETURNS TRIGGER AS $function_end$
    DECLARE
        bk_id integer;
        new_id integer;
        new_cycle_id integer;
        table_name varchar;
        new_haul_id integer;
    BEGIN
        new_haul_id = NEW.haul_id;
        table_name = TG_RELID::regclass;
        SELECT nextval(pg_get_serial_sequence(table_name, 'id')) INTO new_id;
        bk_id = NEW.id;
        NEW.id = new_id;

        UPDATE trans.trans_id_bk SET id=new_id WHERE tablename=table_name AND bk=bk_id AND equip_id=NEW.haul_id;
        IF NOT FOUND THEN
            INSERT INTO trans.trans_id_bk (tablename, id, bk, equip_id) VALUES (table_name, new_id, bk_id, new_haul_id);
        END IF;

        RETURN NEW;
    END;
$function_end$ LANGUAGE plpgsql;

CREATE TRIGGER trans_cycles_before_insert BEFORE INSERT 
ON trans.trans_cycles FOR EACH ROW 
EXECUTE PROCEDURE trans.trans_cycles_bk_process();

DROP FUNCTION IF EXISTS trans.trans_coords_bk_process CASCADE;
CREATE FUNCTION trans.trans_coords_bk_process() RETURNS TRIGGER AS $function_end$
    DECLARE
        bk_id integer;
        new_id integer;
        new_cycle_id integer;
        table_name varchar;
    BEGIN
        table_name = TG_RELID::regclass;

        SELECT nextval(pg_get_serial_sequence(table_name, 'id')) INTO new_id;
        bk_id = NEW.id;
        NEW.id = new_id;

        UPDATE trans.trans_id_bk SET id=new_id WHERE tablename=table_name AND bk=bk_id AND equip_id=NEW.equip_id;
        IF NOT FOUND THEN
            INSERT INTO trans.trans_id_bk (tablename, id, bk, equip_id) VALUES (table_name, new_id, bk_id, NEW.equip_id) ;
        END IF;
        IF NEW.cycle_id IS NOT NULL THEN
            SELECT id FROM trans.trans_id_bk WHERE tablename='trans.trans_cycles' AND bk=NEW.cycle_id AND equip_id = NEW.equip_id INTO new_cycle_id;
            IF new_cycle_id IS NULL THEN
                WITH rows AS 
                (
                    INSERT INTO trans.trans_cycles (haul_id, id) VALUES (NEW.cycle_id, NEW.equip_id) RETURNING id
                ) 
                SELECT rows.id FROM rows INTO new_cycle_id;
            ELSE
                new_cycle_id = NEW.cycle_id;
            END IF;
        END IF;

        NEW.cycle_id = new_cycle_id;
        RETURN NEW;
    END;
$function_end$ LANGUAGE plpgsql;

CREATE TRIGGER trans_coords_before_insert BEFORE INSERT 
ON trans.trans_coord FOR EACH ROW 
EXECUTE PROCEDURE trans.trans_coords_bk_process();