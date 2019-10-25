# Project 3

## Group Members

- Kalpak Seal: 8241-7219
- Sagnik Ghosh: 3343-6044

## Project Directory Structure

```shell
├── README.md
├── _build
├── lib
│   ├── proj3
│   │   ├── master.ex
│   │   ├── node.ex
│   │   ├── stage.ex
│   │   └── starter.ex
│   └── proj3.ex
├── mix.exs
├── proj3.exs
└── test
    ├── proj3_test.exs
    └── test_helper.exs
```

## What is working?

- We have implemented the desired requirements from the Section 3 of the Tapestry research paper.
- We implemented the prefix based routing where a routing request to any node is matched by prefix and the request is transferred to the closest matched node as desired by the algorithm.

### What is the largest network managed to deal with?

- Number of Nodes: 10000
- Number of Requests: Any reasonable value. For ex: 10.

```shell
mix run proj3.exs 10000 10
In Starter
E4B5 trying to reach 456B
The above request completed in hops: 2
Sending all requests to calculate maximum hops in network for any routing...
Maximum Hops done: 3
```

## Instruction for running the code

1. Unzip the file.
2. cd proj3
3. mix run proj3.exs <numNodes> <numRequests>

| Argument    | Possible Values      |
| ----------- | -------------------- |
| numNodes    | Any positive integer |
| numRequests | Any positive integer |

## Implementation and Inference

We begin with 16 root nodes which forms the top layer of the Tapestry structure. We have taken 4-digit hexadecimal values to identify each of our nodes, such as AB23, 657F, etc.

When new nodes join into the network, 

- they find their closest match with the existing nodes and thereby selects their parent to inherit the routing information.
- the parent updates its own table with the node information of this newly added node and propagates the same information to all the other nodes in the same level of its routing table and the nodes below that level too.
- the fellow nodes, on receiving this information from the aforementioned root node about the newly entered node, will multicast the information to all the nodes present a ***level below***, in its own routing table.

Thus, for every new node added to the network, the root node for the same updates the routing table of itself and all other nodes' routing table in its own sub-tree subsequently.

#### Lookup / Routing

![](/Users/kalpak/Desktop/Screen Shot 2019-10-25 at 1.58.19 PM.png)

**Route message from 5230 to 42AD** 

- Always route to node closer to target

- At nth hop, look at n+1th level in neighbor map --> “always” one digit more.
- Not all nodes and links are shown

## Test Results

| Num_request | num_nodes | max_hop |
| ----------- | --------- | ------- |
| 5           | 20        | 1       |
| 7           | 50        | 2       |
| 12          | 500       | 2       |
| 14          | 1000      | 3       |
| 40          | 2000      | 3       |
| 50          | 5000      | 3       |

We can thereby infer that with the increase of the number of nodes, they are evenly distributed in the tapestry address space and they are available to be reached by a maximum of 3 hop count which is expected, as each node is identified by 4 hexadecimal digits.

The maximum number of nodes possible to accomodate in our implementation is 16^4 = 65536.

## Modules

### Master

This module remembers the node present in network and mapping of those to the PIDs of the processes.

#### put (Node Name, PID) ####

- Puts the node it in master's node_list.
- Creates mapping of node and respective PIDs.

#### get (Node Name) ####

- Returns the list of active nodes in the network. 

#### lookup (Node Name) ####

- Returns the respective node's PID

###  Node

#### gettable

- Returns the routing table

#### lookup

- Find the node or the closest match for the destination node.

#### update_parent(self_id,parent)

- Requests the parent node to update its routing table with the address of the node.

### Stage

#### send_request(numRequest)

- Sends request from one node to the other based on `numRequest` .



