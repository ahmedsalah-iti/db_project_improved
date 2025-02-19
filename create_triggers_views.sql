-- SOURCE /home/as/Desktop/db_project_improved/create_tables.sql; SOURCE /home/as/Desktop/db_project_improved/create_functions.sql; SOURCE /home/as/Desktop/db_project_improved/create_triggers_views.sql;

DELIMITER //
create TRIGGER after_cash_payment
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
    DECLARE orderPrice DECIMAL(10,2);
    DECLARE orderUserId INT;
    DECLARE userBalance DECIMAL(10,2);
    DECLARE trStatus ENUM('completed', 'failed');

    SET orderPrice = getOrderTotalPrice(NEW.order_id);
    select user_id into orderUserId from `Order` WHERE id = NEW.order_id;
    SET userBalance = getUserBalance(orderUserId);
    SET trStatus = 'failed';

    if NEW.method = 'cash' then
        if userBalance >= orderPrice then
            if (subUserBalance(orderUserId,orderPrice)) then
                SET trStatus = 'completed';
            end if;
        end if;
        update Payment set status = trStatus where id = NEW.id;
        insert into Wallet_Transaction (
            user_id,
            type,
            amount,
            balance_before,
            balance_after,
            status
        )
        VALUES (
            orderUserId,
            'sub',
            orderPrice,
            getUserBalance(orderUserId),
            getUserBalance(orderUserId) - orderPrice,
            trStatus 
        );
    end if;

END //
DELIMITER ;

/*
create VIEW LatestOrderedProducts as SELECT
product_id,
(select name from Product where id = Order_Product.product_id) as product_name,
quantity,
(select price from Product where id = Order_Product.product_id) as price,
(select date from `Order` where id = Order_Product.product_id) as order_date
from Order_Product
where order_id in (
    select id from `Order`
    where user_id = 
    ORDER BY date desc, id DESC
)
order by order_date desc;
*/
CREATE VIEW LatestOrderedProducts AS
SELECT
    o.user_id,
    o.id AS order_id,
    op.id AS order_product_id,
    op.product_id,
    p.name AS product_name,
    o.date AS order_date,
    p.price
FROM
    `Order` o
INNER JOIN
    Order_Product op ON o.id = op.order_id
INNER JOIN
    Product p ON op.product_id = p.id
INNER JOIN (
    SELECT user_id, MAX(date) AS max_date
    FROM `Order`
    GROUP BY user_id
) AS latest_orders ON o.user_id = latest_orders.user_id AND o.date = latest_orders.max_date
ORDER BY
    o.user_id, o.date DESC;