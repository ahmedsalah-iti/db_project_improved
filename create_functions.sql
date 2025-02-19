-- SOURCE /home/as/Desktop/db_project_improved/create_tables.sql; SOURCE /home/as/Desktop/db_project_improved/create_functions.sql;

DELIMITER //
create FUNCTION isUserIdExists(userId int) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from User WHERE id = userId;
    RETURN isFound;
END //
DELIMITER ;

DELIMITER //
create FUNCTION isUserEmailExists(userEmail VARCHAR(100)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from User WHERE email = userEmail;
    RETURN isFound;
END //
DELIMITER ;


DELIMITER //
create FUNCTION isPhoneExists(userPhone VARCHAR(11)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from User WHERE phone = userPhone;
    RETURN isFound;
END //
DELIMITER ;


DELIMITER //
create FUNCTION isOrderIdExists(orderId int) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from `Order` WHERE id = orderId;
    RETURN isFound;
END //
DELIMITER ;


DELIMITER //
create FUNCTION isProductAvailable(productId int) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from Product WHERE id = productId and `status` = TRUE;
    RETURN isFound;
END //
DELIMITER ;


DELIMITER //
create FUNCTION isRoomExists(roomId int) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isFound BOOLEAN;
    SELECT COUNT(*) > 0 into isFound from Room WHERE id = roomId;
    RETURN isFound;
END //
DELIMITER ;


DELIMITER //
CREATE FUNCTION getOrderTotalPrice(orderId INT) RETURNS decimal(10,2)
DETERMINISTIC
BEGIN
    DECLARE total decimal(10,2);
    SELECT sum(price_at_purchase * quantity) into total from Order_Product where order_id = orderId;
    RETURN total;
END //

DELIMITER ;


DELIMITER //
create PROCEDURE addNewUser(
    IN userEmail VARCHAR(100),
    IN fName varchar(50),
    IN lName varchar(50),
    IN roomId int,
    IN userPhone varchar(11),
    IN hashedPassword varchar(255),
    IN userRole ENUM('admin','customer')
)
BEGIN
    if NOT isRoomExists(roomId) then
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error 1002: Room not found yet.';
    end if;

    
    INSERT INTO  User (
        first_name,
        last_name,
        email,
        phone,
        password,
        room_id,
        profile_img,
        role
        ) VALUES(
         fName,
         lName,
         userEmail,
         userPhone,
         hashedPassword,
         roomId,
         null,
         userRole
    );

END //
DELIMITER ;


DELIMITER //
create FUNCTION getUserBalance(userID int) RETURNS decimal(10,2)
DETERMINISTIC
BEGIN
    DECLARE userBalance decimal(10,2);
    select COALESCE(sum(
        CASE 
            WHEN type = 'add' THEN amount 
            WHEN type = 'sub' THEN -amount 
            ELSE 0 
        END
    ),0.00) into userBalance
    from Wallet_Transaction WHERE user_id = userID AND status = 'completed';
    RETURN userBalance;
END //
DELIMITER ;


DELIMITER //
CREATE FUNCTION getUserBalance2(userID INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE userBalance DECIMAL(10,2);

    SELECT COALESCE(balance_after, 0.00) 
    INTO userBalance
    FROM Wallet_Transaction 
    WHERE user_id = userID AND status = 'completed'
    ORDER BY made_at DESC, id DESC
    LIMIT 1;

    RETURN userBalance;
END //
DELIMITER ;




DELIMITER //
create function addUserBalance(userID int, addAmount decimal(10,2)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isDone BOOLEAN;
    DECLARE currentUserBalance decimal(10,2);
    DECLARE newUserBalance decimal(10,2);
    DECLARE trStatus VARCHAR(10);
    SET isDone = TRUE;
    SET trStatus = 'completed';
    if NOT isUserIdExists(userID) THEN
        SET trStatus = 'failed';
        SET isDone = FALSE;
        RETURN isDone;
    END if;
    if addAmount <= 0 THEN
        SET trStatus = 'failed';
        SET isDone = FALSE;
    end if;

    SET currentUserBalance = getUserBalance(userID);
    SET newUserBalance = currentUserBalance + addAmount;

    INSERT INTO Wallet_Transaction ( 
        type,
        amount,
        balance_before,
        balance_after,
        user_id,
        status
     ) VALUES(
         'add',
         addAmount,
         currentUserBalance,
         newUserBalance,
         userID,
         trStatus
    );
     
    IF getUserBalance2(userID) = newUserBalance AND isDone = TRUE THEN 
        RETURN isDone;
    else
        SET isDone = FALSE;
        RETURN isDone;
    end if;
END //
DELIMITER ;


DELIMITER //
create function subUserBalance(userID int , subAmount decimal(10,2)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE isDone BOOLEAN;
    DECLARE currentUserBalance decimal(10,2);
    DECLARE newUserBalance decimal(10,2);
    DECLARE trStatus VARCHAR(10);
    SET isDone = TRUE;
    SET trStatus = 'completed';
    if NOT isUserIdExists(userID) THEN
        SET trStatus = 'failed';
        SET isDone = FALSE;
        RETURN isDone;
    END if;
    SET currentUserBalance = getUserBalance(userID);
    SET newUserBalance = currentUserBalance - subAmount;
    if subAmount <= 0.00 OR newUserBalance < 0.00 THEN
        SET trStatus = 'failed';
        SET isDone = FALSE;
    end if;

    INSERT INTO Wallet_Transaction ( 
        type,
        amount,
        balance_before,
        balance_after,
        user_id,
        status
     ) VALUES(
         'sub',
         subAmount,
         currentUserBalance,
         newUserBalance,
         userID,
         trStatus
    );
    IF getUserBalance(userID) = newUserBalance AND isDone = TRUE THEN
        RETURN isDone;
    else
        SET isDone = FALSE;
        RETURN isDone;
    end if;
END //
DELIMITER ;
