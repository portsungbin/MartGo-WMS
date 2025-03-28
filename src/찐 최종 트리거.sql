DROP TRIGGER IF EXISTS insert_stock;
DELIMITER $$
CREATE TRIGGER insert_stock
    AFTER UPDATE ON incoming
    FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    DECLARE v_product_price INT;
    DECLARE v_product_id VARCHAR(100);
    DECLARE v_total_price INT;
    DECLARE v_user_id VARCHAR(100);
    DECLARE v_stock_num INT;
    DECLARE v_sector_id CHAR(3);
    DECLARE v_warehouse_id INT;
    DECLARE stock_not_fount INT DEFAULT 0;

    -- 기존에 존재하는 stock 레코드를 찾고 없으면 1로 설정
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET stock_not_fount = 1;

-- 완료 처리된 입고 번호를 통해 제품 id, 수량, 유저 id를 들고옴
    SELECT product_id, count, user_id
    INTO v_product_id, v_count, v_user_id
    FROM incoming
    WHERE incoming_num = NEW.incoming_num
    LIMIT 1;

-- 제품에서 해당 제품의 가격을 들고옴
    SELECT price
    INTO v_product_price
    FROM product
    WHERE product_id = v_product_id
    LIMIT 1;

-- 총 가격을 계산해서 할당
    SET v_total_price = v_count * v_product_price;

-- 섹터 아이디와 창고 아이디를 들고옴
    SELECT sector_id, warehouse_id
    INTO v_sector_id, v_warehouse_id
    FROM rent_history
    WHERE user_id = v_user_id
    LIMIT 1;

    SELECT stock_num
    INTO v_stock_num
    FROM stock
    WHERE user_id = v_user_id
      AND product_id = v_product_id
    LIMIT 1;


    IF NEW.status = '완료' AND OLD.status <> '완료' THEN
        IF stock_not_fount = 1 THEN
            INSERT INTO stock (count, total_price, user_id, product_id, sector_id, warehouse_id)
            VALUES (v_count, v_total_price, v_user_id, v_product_id, v_sector_id, v_warehouse_id);
            SET v_stock_num = LAST_INSERT_ID();
        ELSE
            UPDATE stock
            SET count        = count + v_count,
                total_price  = total_price + v_total_price,
                user_id      = v_user_id,
                sector_id    = v_sector_id,
                warehouse_id = v_warehouse_id
            WHERE stock_num = v_stock_num;
        END IF;
    END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS outgoing_stock;
DELIMITER $$
CREATE TRIGGER outgoing_stock
    AFTER UPDATE ON outgoing
    FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    DECLARE v_product_price INT;
    DECLARE v_product_id VARCHAR(100);
    DECLARE v_total_price INT;
    DECLARE v_user_id VARCHAR(100);
    DECLARE v_stock_num INT;
    DECLARE stock_not_found INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET stock_not_found = 1;

-- 완료 처리된 출고 번호를 통해 수량, 재고번호를 들고옴
    SELECT count, stock_num
    INTO v_count, v_stock_num
    FROM outgoing
    WHERE outgoing_num = NEW.outgoing_num;

    SELECT user_id, product_id
    INTO v_user_id, v_product_id
    FROM stock
    WHERE stock_num = v_stock_num;

-- 제품에서 해당 제품의 가격을 들고옴
    SELECT price
    INTO v_product_price
    FROM product
    WHERE product_id = v_product_id;

-- 총 가격을 계산해서 할당
    SET v_total_price = v_count * v_product_price;


    IF NEW.status = '완료' AND OLD.status <> '완료' THEN
        IF stock_not_found = 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '해당 재고가 없습니다.';
        ELSE
            UPDATE
                stock
            SET count       = count - v_count,
                total_price = total_price - v_total_price
            WHERE stock_num = v_stock_num;
        END IF;
    end if;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS insert_stock_history;
DELIMITER $$
CREATE TRIGGER insert_stock_history
    AFTER INSERT ON stock
    FOR EACH ROW
BEGIN
    DECLARE v_product_id VARCHAR(100);
    DECLARE v_user_id VARCHAR(100);
    DECLARE v_admin_id VARCHAR(100);
    DECLARE v_sector_id CHAR(3);
    DECLARE v_warehouse_id INT;
    DECLARE v_count INT;
    DECLARE v_incoming_num INT;
    DECLARE v_stock_num INT;

    -- 제품 아이디, 수량, 유저 아이디 불러오기
    SELECT product_id, count, user_id
    INTO v_product_id, v_count, v_user_id
    FROM stock
    WHERE stock_num = NEW.stock_num;

    -- 유저 아이디를 통해 어드민 아이디 불러오기
    SELECT admin_id
    INTO v_admin_id
    FROM user
    WHERE user_id = v_user_id;

    -- 섹터 아이디와 창고 아이디를 들고옴
    SELECT sector_id, warehouse_id
    INTO v_sector_id, v_warehouse_id
    FROM rent_history
    WHERE user_id = v_user_id
    LIMIT 1;

    -- 입고 번호 들고오기
    SELECT incoming_num
    INTO v_incoming_num
    FROM incoming
    WHERE user_id = v_user_id
      AND status = '완료'
    LIMIT 1;



    -- 유저 아이디와 제품 아이디를 통해 재고번호 들고오기
    SELECT stock_num
    INTO v_stock_num
    FROM stock
    WHERE user_id = v_user_id
      AND product_id = v_product_id
    LIMIT 1;

    INSERT INTO stock_history
    (product_id, sector_id, count, change_date,
     change_type, admin_id, stock_num, incoming_num, outgoing_num)
    VALUES (v_product_id,v_sector_id,v_count,SYSDATE(),
            '입고',v_admin_id,v_stock_num,v_incoming_num, null);

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS update_stock_history;
DELIMITER $$
CREATE TRIGGER update_stock_history
    AFTER UPDATE ON stock
    FOR EACH ROW
BEGIN
    DECLARE v_product_id VARCHAR(100);
    DECLARE v_user_id VARCHAR(100);
    DECLARE v_admin_id VARCHAR(100);
    DECLARE v_sector_id CHAR(3);
    DECLARE v_warehouse_id INT;
    DECLARE v_change INT;
    DECLARE v_incoming_num INT;
    DECLARE v_outgoing_num INT;
    DECLARE v_stock_num INT;

    -- NEW 값을 이용해 정확한 행의 제품 아이디, 유저 아이디, 재고 번호 지정
    SET v_product_id = NEW.product_id;
    SET v_user_id = NEW.user_id;
    SET v_stock_num  = NEW.stock_num;

    -- 유저 아이디를 통해 어드민 아이디 불러오기
    SELECT admin_id
    INTO v_admin_id
    FROM user
    WHERE user_id = v_user_id;

    -- 섹터 아이디와 창고 아이디 불러오기
    SELECT sector_id, warehouse_id
    INTO v_sector_id, v_warehouse_id
    FROM rent_history
    WHERE user_id = v_user_id
    LIMIT 1;

    IF NEW.count > OLD.count THEN
        -- 입고인 경우
        SET v_change = NEW.count - OLD.count;

        SELECT incoming_num
        INTO v_incoming_num
        FROM incoming i
        WHERE NOT EXISTS (
            SELECT 1
            FROM stock_history sh
            WHERE sh.incoming_num = i.incoming_num
        )
        LIMIT 1;

        INSERT INTO stock_history
        (product_id, sector_id, count, change_date, change_type, admin_id,
         stock_num, incoming_num, outgoing_num)
        VALUES (v_product_id, v_sector_id, v_change, NOW(),
                '입고', v_admin_id, v_stock_num, v_incoming_num, NULL);

    ELSEIF NEW.count < OLD.count THEN
        -- 출고인 경우
        SET v_change = OLD.count - NEW.count;

        SELECT outgoing_num
        INTO v_outgoing_num
        FROM outgoing o
        WHERE NOT EXISTS (
            SELECT 1
            FROM stock_history sh
            WHERE sh.outgoing_num = o.outgoing_num
        )
        LIMIT 1;

        INSERT INTO stock_history
        (product_id, sector_id, count, change_date, change_type, admin_id,
         stock_num, incoming_num, outgoing_num)
        VALUES (v_product_id, v_sector_id, v_change, NOW(),
                '출고', v_admin_id, v_stock_num, NULL, v_outgoing_num);
    END IF;
END $$
DELIMITER ;

-- admin_id가 데이터베이스에 입력될 예정이면 상태를 진행중으로 변경하는 트리거
drop trigger if exists SetRentStatus;
DELIMITER //
CREATE TRIGGER SetRentStatus
    BEFORE UPDATE ON rent_history
    FOR EACH ROW
BEGIN
    IF OLD.admin_id IS NULL AND NEW.admin_id IS NOT NULL THEN
        SET NEW.status = '진행중';
    END IF;
END //
DELIMITER ;
-- 재고에 제품이 입력되면 제품의 부피 계산하여 섹터의 용적률에 적용하는 트리거
DROP TRIGGER IF EXISTS updateSectorAndWarehouseFar;
DELIMITER //
CREATE TRIGGER updateSectorAndWarehouseFar
    AFTER UPDATE ON stock
    FOR EACH ROW
BEGIN
    DECLARE sector_total_volume INTEGER;
    DECLARE warehouse_total_volume INTEGER;
    DECLARE current_sector_far DECIMAL(6,2);
    DECLARE current_warehouse_far DECIMAL(6,2);
    DECLARE product_volume_change INTEGER;
    SELECT height * width INTO sector_total_volume
    FROM sector
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;
    SELECT height * width INTO warehouse_total_volume
    FROM warehouse
    WHERE warehouse_id = NEW.warehouse_id;
    SELECT FAR INTO current_sector_far
    FROM sector
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;
    SELECT FAR INTO current_warehouse_far
    FROM warehouse
    WHERE warehouse_id = NEW.warehouse_id;
    SET product_volume_change = (NEW.count - OLD.count) *
                                (SELECT height * width FROM product WHERE product_id = NEW.product_id);
    UPDATE sector
    SET FAR = current_sector_far + (product_volume_change / sector_total_volume) * 100
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;
    UPDATE warehouse
    SET FAR = current_warehouse_far + (product_volume_change / warehouse_total_volume) * 100
    WHERE warehouse_id = NEW.warehouse_id;
END;
//
DELIMITER ;
-- 창고 임대 테이블의 상태가 완료로 변경되면 해당 섹터의 상태를 사용불가로 변경
drop trigger if exists update_sector_status;
DELIMITER //
CREATE TRIGGER update_sector_status
    AFTER UPDATE ON rent_history
    FOR EACH ROW
BEGIN
    -- 상태가 '완료'로 변경된 경우에만 처리
    IF NEW.status = '완료' AND OLD.status != '완료' THEN
        -- 해당 섹터의 상태를 '사용불가'로 변경
        UPDATE sector
        SET status = '사용불가'
        WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;
    END IF;
END;
//
DELIMITER ;
-- 임대 내역 테이블의 상태가 완료로 변경되면 회원의 role을 거래처로 변경
drop trigger if exists updateUserRole;
CREATE TRIGGER updateUserRole
    AFTER UPDATE ON rent_history
    FOR EACH ROW
BEGIN
    IF NEW.status = '완료' AND OLD.status = '진행중' THEN
        UPDATE `user`
        SET role = '거래처'
        WHERE user_id = NEW.user_id;
    END IF;
END;

drop trigger if exists updateInsertSectorAndWarehouseFar;


DELIMITER //
CREATE TRIGGER updateInsertSectorAndWarehouseFar
    AFTER INSERT ON stock
    FOR EACH ROW
BEGIN
    DECLARE sector_total_volume INTEGER;
    DECLARE warehouse_total_volume INTEGER;
    DECLARE current_sector_far DECIMAL(6,2);
    DECLARE current_warehouse_far DECIMAL(6,2);
    DECLARE product_volume_change INTEGER;

    SELECT height * width INTO sector_total_volume
    FROM sector
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;

    SELECT height * width INTO warehouse_total_volume
    FROM warehouse
    WHERE warehouse_id = NEW.warehouse_id;

    SELECT FAR INTO current_sector_far
    FROM sector
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;

    SELECT FAR INTO current_warehouse_far
    FROM warehouse
    WHERE warehouse_id = NEW.warehouse_id;

    SET product_volume_change = NEW.count *
                                (SELECT height * width FROM product WHERE product_id = NEW.product_id);

    UPDATE sector
    SET FAR = current_sector_far + (product_volume_change / sector_total_volume) * 100
    WHERE sector_id = NEW.sector_id AND warehouse_id = NEW.warehouse_id;

    UPDATE warehouse
    SET FAR = current_warehouse_far + (product_volume_change / warehouse_total_volume) * 100
    WHERE warehouse_id = NEW.warehouse_id;
END//


DELIMITER ;