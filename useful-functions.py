import array
import json


# Functions for the first challenge
def compare_get_tokens_with_not_found_tokens():
    f1 = open('getRequests')
    get_requests = json.load(f1)

    f2 = open('notFoundResponses')
    not_found = json.load(f2)

    count = 0

    for i in get_requests:
        token_request = i["_source"]["layers"]["coap"]["coap.token"]
        for j in not_found:
            token_response = j["_source"]["layers"]["coap"]["coap.token"]
            if token_request == token_response:
                count += 1

    print(count)

    f1.close()
    f2.close()


def compare_client_admin_with_publisher():
    f1 = open('mqttAdminPss')
    users_admin = json.load(f1)

    f2 = open('publishFactoryDep')
    factory_dep_publishers = json.load(f2)

    for i in users_admin:
        port_admin_user = i["_source"]["layers"]["tcp"]["tcp.srcport"]
        ip_admin_user = i["_source"]["layers"]["ip"]["ip.src"]
        for j in factory_dep_publishers:
            port_factory_dep_publisher = j["_source"]["layers"]["tcp"]["tcp.srcport"]
            ip_factory_dep_publisher = j["_source"]["layers"]["ip"]["ip.src"]
            if port_admin_user == port_factory_dep_publisher and ip_admin_user == ip_factory_dep_publisher:
                print(j["_source"]["layers"]["mqtt"]["mqtt.topic"])

    f1.close()
    f2.close()


def calculate_average():
    f = open('mqttVer3')
    mqtt_ver_3 = json.load(f)
    list_len = []

    for i in mqtt_ver_3:
        list_len.append(int(i["_source"]["layers"]["mqtt"]["mqtt.len"]))

    avg_value = sum(list_len) / len(list_len)
    print(avg_value)
    f.close()

