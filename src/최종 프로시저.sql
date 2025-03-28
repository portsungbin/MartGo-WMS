-- 총관리자가 진행중 상태인 임대신청내역을 승인하면 상태를 완료로 수정하는 프로시저
drop procedure if exists CompletedRentStatus;
DELIMITER $$
CREATE PROCEDURE CompletedRentStatus(IN p_rent_num INT, IN p_admin_id VARCHAR(100))
BEGIN
    DECLARE v_warehouse_id INT;
    SELECT rh.warehouse_id INTO v_warehouse_id
    FROM rent_history rh
             JOIN admin a ON rh.warehouse_id = a.warehouse_id
    WHERE rh.rent_num = p_rent_num
      AND a.admin_id = p_admin_id
      AND rh.status = '진행중';
    IF v_warehouse_id IS NOT NULL THEN
        UPDATE rent_history
        SET status = '완료'
        WHERE rent_num = p_rent_num;
    END IF;
END $$
DELIMITER ;
-- 입력 받은 창고id의 있는 섹터 출력하는 프로시저
drop procedure if exists GetAllSectors;
DELIMITER //
create procedure GetAllSectors(IN p_warehouse_id int)
BEGIN
    SELECT * FROM sector
    WHERE warehouse_id = p_warehouse_id
      AND status = '사용가능';
END//
DELIMITER ;
-- 모든 창고의 정보를 가져오는 프로시저
drop procedure if exists GetAllWarehouses;
DELIMITER //
create procedure GetAllWarehouses()
BEGIN
    SELECT * FROM warehouse;
END//
DELIMITER ;
-- 선택한 창고와 섹터와 기간에 해당하는 가격 출력하는 프로시저
drop procedure if exists GetCostInfo;
delimiter //
create procedure GetCostInfo(IN p_warehouse_id int, IN p_sector_id varchar(10),
                             IN p_period varchar(10))
BEGIN
    SELECT price FROM cost_info
    WHERE warehouse_id = p_warehouse_id
      AND sector_id = p_sector_id
      AND period = p_period;
END//
delimiter ;
-- 선택한 창고와 섹터의 모든 기간별 가격 출력하는 프로시저
drop procedure if exists GetCostInfoSector;
delimiter //
create procedure GetCostInfoSector(IN p_warehouse_id int, IN p_sector_id varchar(10))
BEGIN
    SELECT `period`, price
    FROM cost_info
    WHERE warehouse_id = p_warehouse_id
      AND sector_id = p_sector_id;
END//
delimiter ;
-- 임대 내역 테이블에서 상태가 대기 인 레코드 모두 출력하는 프로시저
drop procedure if exists GetholdRentHistory;
delimiter //
create procedure GetholdRentHistory()
BEGIN
    SELECT * FROM rent_history WHERE status = '대기';
END//
delimiter ;
-- 임대내역 테이블에서 상태가 진행중인 레코드 모두 출력하는 프로시저
drop procedure if exists GetInProgressRentHistory;
DELIMITER //
CREATE PROCEDURE GetInProgressRentHistory(IN p_admin_id VARCHAR(100))
BEGIN
    SELECT rh.*
    FROM rent_history rh
             JOIN admin a ON rh.warehouse_id = a.warehouse_id
    WHERE a.admin_id = p_admin_id AND rh.status = '진행중';
END //
DELIMITER ;
-- 임대신청시 회원이 입력한 정보 임대내역 테이블에 저장하는 프로시저
drop procedure if exists InsertRentHistory;
delimiter //
create  procedure InsertRentHistory(IN p_sector_id varchar(10), IN p_warehouse_id int,
                                    IN p_rent_start_date date, IN p_rent_end_date date,
                                    IN p_rent_price int, IN p_user_id varchar(100))
BEGIN
    INSERT INTO rent_history (sector_id, warehouse_id, rent_start_date, rent_end_date, rent_price, user_id)
    VALUES (p_sector_id, p_warehouse_id, p_rent_start_date, p_rent_end_date, p_rent_price, p_user_id);
END//
delimiter ;
-- 회원가입한 회원 정보를 user테이블에 저장하는 프로시저 (성빈님꺼)
drop procedure if exists InsertUser;
delimiter //
create procedure InsertUser(IN p_user_id varchar(100), IN p_user_name varchar(100),
                            IN p_user_pw varchar(100), IN p_phone varchar(100),
                            IN p_email varchar(100), IN p_address varchar(100),
                            IN p_role enum ('회원', '거래처'), IN p_admin_id varchar(100))
BEGIN
    IF p_role IS NULL THEN
        SET p_role = '회원';
    END IF;
    INSERT INTO User (user_id, user_name, user_pw, phone, email, address, role, admin_id)
    VALUES (p_user_id, p_user_name, p_user_pw, p_phone, p_email, p_address, p_role, p_admin_id);
END//
delimiter ;
-- 창고관리자가 임대 내역테이블에 대기 상태인 것을 승인하면 해당 레코드에 본인의(admin) id를 저장하는 프로시저
drop procedure if exists UpdateAdminId;
delimiter //
create procedure UpdateAdminId(IN p_rent_num int, IN p_admin_id varchar(100))
BEGIN
    UPDATE rent_history
    SET admin_id = p_admin_id
    WHERE rent_num = p_rent_num;
END//
delimiter ;
-- 임대 내역테이블에 adminid가 추가되면(진행중으로 승인되면) user테이블에 해당 adminid저장
drop procedure if exists updateUserAdminid;
delimiter //
create procedure updateUserAdminid()
BEGIN
    UPDATE `user` u
        JOIN rent_history rh ON u.user_id = rh.user_id
    SET u.admin_id = rh.admin_id
    WHERE rh.admin_id IS NOT NULL
      AND u.user_id = rh.user_id;
END//
delimiter ;