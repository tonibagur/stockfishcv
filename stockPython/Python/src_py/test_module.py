import numpy as np

def group(values):
    import numpy as np
    values = np.array(values)
    values.sort()
    dif = np.ones(values.shape,values.dtype)
    dif[1:] = np.diff(values)
    idx = np.where(dif>0)
    vals = values[idx]
    count = np.diff(idx)
    return vals

def dist(x1,x2,y1,y2):
    return ((x1-x2)**2 + (y1-y2)**2)**0.5

def cluster_points(x_arr, y_arr, dist_th=10, clust_th=10):
    clusters=np.ones((x_arr.shape[0],))*-1
    for i in range(x_arr.shape[0]):
        dists=dist(x_arr, x_arr[i], y_arr, y_arr[i])
        dist_filter=dists<=dist_th
        without_cluster=np.logical_and(dist_filter,clusters==-1)
        clusters[without_cluster]=i
        different_clusters=group(clusters[dist_filter])
        for c in different_clusters:
            clusters[clusters==c]=i
    clust=group(clusters)
    x_arr2=[]
    y_arr2=[]
    for c in clust:
        if clusters[clusters==c].shape[0]>clust_th:
            x_arr2.append(np.mean(x_arr[clusters == c]))
            y_arr2.append(np.mean(y_arr[clusters == c]))
    x_arr=np.array(x_arr2)
    y_arr=np.array(y_arr2)
    return x_arr,y_arr

def get_conv_coords(conv_factor,conv_out_y,conv_out_x):
    x_rand = []
    y_rand = []
    for k in range(conv_out_y):
        for u in range(conv_out_x):
            y_rand.append((k + 1) * conv_factor)
            x_rand.append((u + 1) * conv_factor)
    x_rand = np.array(x_rand)
    y_rand = np.array(y_rand)
    return x_rand,y_rand

def test_function(model_out):
    print model_out.shape
    conv_factor=4
    conv_out_y=160
    conv_out_x=120
    x,y=get_conv_coords(conv_factor,conv_out_y,conv_out_x)
    print np.swapaxes(model_out[0,:,:],0,1)
    probs=np.swapaxes(model_out[0,:,:],0,1).reshape(-1)>0.9
    print "sum",np.swapaxes(model_out[0,:,:],0,1).reshape(-1).sum(),probs.sum()
    print "probs",probs
    x=x[probs]
    y=y[probs]
    print "x,y",x,y
    _,y_clust=cluster_points(np.ones(y.shape[0])*200,y , dist_th=5, clust_th=1)
    x_clust,_=cluster_points(x, np.ones(x.shape[0])*200, dist_th=5, clust_th=1)
    nx,ny=x_clust.shape[0],y_clust.shape[0]
    min_x=np.min(x_clust)
    max_x=np.max(x_clust)
    min_y=np.min(y_clust)
    max_y=np.max(y_clust)
    #ratio=(max_x - min_x)/(max_y-min_y)
    print "nx,ny",nx,ny,x_clust,y_clust
    print "xmin,ymin,xmax,ymax",min_x,min_y,max_x,max_y
    return min_x,min_y,max_x,max_y
